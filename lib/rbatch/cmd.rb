require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'timeout'
module RBatch

  # External command wrapper
  class Cmd
    # @private
    @@def_vars

    # @private
    # @param [RBatch::Variables] vars
    def Cmd.def_vars=(vars)    ; @@def_vars=vars ; end

    # command string
    @cmd_str
    
    # option
    @opt

    # @private
    @vars

    # @param [String] cmd_str command string such as "ls -l"
    # @option opt [Boolean] :raise
    # @option opt [Integer] :timeout
    def initialize(cmd_str,opt = nil)
      raise(CmdException,"Command string is nil") if cmd_str.nil?
      @cmd_str = cmd_str
      @vars = @@def_vars.clone
      if ! opt.nil?
        # change opt key from "hoge" to "log_hoge"
        tmp = {}
        opt.each_key do |key|
          tmp[("cmd_" + key.to_s).to_sym] = opt[key]
        end
        @vars.merge!(tmp)
      end
    end

    # Run command
    # @raise [RBatch::CmdException]
    # @return [RBatch::CmdResult]
    def run()
      stdout_file = Tempfile::new("rbatch_tmpout",Dir.tmpdir)
      stderr_file = Tempfile::new("rbatch_tmperr",Dir.tmpdir)
      pid = spawn(@cmd_str,:out => [stdout_file,"w"],:err => [stderr_file,"w"])
      status = nil
      if @vars[:cmd_timeout] != 0
        begin
          timeout(@vars[:cmd_timeout]) do
            status =  Process.waitpid2(pid)[1] >> 8
          end
        rescue Timeout::Error => e
          begin
            Process.kill('SIGINT', pid)
            raise(CmdException,"Run time of command \"#{@cmd_str}\" is over #{@vars[:cmd_timeout].to_s} sec. Success to kill process : PID=#{pid}" )
          rescue
            raise(CmdException,"Run time of command \"#{@cmd_str}\" is over #{@vars[:cmd_timeout].to_s} sec. But Fail to kill process : PID=#{pid}" )
          end
        end
      else
        status =  Process.waitpid2(pid)[1] >> 8
      end
      result = RBatch::CmdResult.new(stdout_file,stderr_file,status,@cmd_str)
      if @vars[:cmd_raise] && status != 0
        raise(CmdException,"Command exit status is not 0. result: " + result.to_s)
      end
      return result
    end
  end

  # Result of external command wrapper
  class CmdResult

    # Tmp file including STDOUT String
    # @return [File]
    attr_reader :stdout_file

    # Tmp file including STDERROR String
    # @return [File]
    attr_reader :stderr_file

    # Exit status
    # @return [Integer]
    attr_reader :status

    # Command string
    # @return [String]
    attr_reader :cmd_str

    # @private
    def initialize(stdout_file, stderr_file, status, cmd_str)
      @stdout_file = stdout_file
      @stderr_file = stderr_file
      @status = status
      @cmd_str = cmd_str
    end

    # STDOUT String
    # @return [String]
    def stdout
      File.read(@stdout_file)
    end

    # STDERR String
    # @return [String]
    def stderr
      File.read(@stderr_file)
    end

    # Return hash including cmd_str, std_out, std_err, and status
    # @return [Hash]
    def to_h
      {:cmd_str => @cmd_str,:stdout => stdout, :stderr => stderr, :status => status}
    end
    
    # Return string including cmd_str, std_out, std_err, and status
    # @return [String]
    def to_s
      to_h.to_s
    end
  end

  class CmdException < StandardError ; end
end
