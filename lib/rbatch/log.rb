require 'logger'
require 'pathname'

module RBatch
  class Log
    @@verbose = false
    @@def_opt = {
      :name      => "<date>_<time>_<prog>.log",
      :dir       => File.join(File.dirname(RBatch.program_name), ".." , "log"),
      :formatter => nil,
      :append    => false,
      :level     => "info"
    }
    @@log_level_map = {
      "debug" => Logger::DEBUG,
      "info"  => Logger::INFO,
      "warn"  => Logger::WARN,
      "error" => Logger::ERROR,
      "fatal" => Logger::FATAL
    }

    @opt

    # Set verbose mode flag.
    def Log.verbose=(bol); @@verbose = bol ; end
    # Get verbose mode flag.
    def Log.verbose ; @@verbose ; end
    # Get Option
    def opt; @opt ; end

    # Auto Logging Block.
    # 
    # ==== Sample
    #  RBatch::Log.new({:level => Logger::INFO}){ |log|
    #    log.info "info string"
    #    log.error "error string"
    #    raise "exception"
    #  }
    #
    # ==== Params
    # +opt+ = Option hash object. Hash keys is follows.
    # - +:name+ (String) = log file name. Default is "<date>_<time>_<prog>.log".
    # - +:dir+ (String) = log direcotry path. Default is "../log"
    # - +:formatter+ (String) = log formatter. "Logger#formatter= "
    # - +:level+ (String) = log level. ["debug"|"info"|"warn"|"error"|"fatal"] . Default is "info".
    # - +:append+ (Boolean) = appned to log or not(=overwrite). Default is ture.
    # ==== Block params
    # +log+ = Instance of +Logger+
    def initialize(opt = nil)
      # parse option
      @opt = @@def_opt.clone
      @@def_opt.each_key do |key|
        if opt != nil  && opt[key]
          # use argument
          @opt[key] = opt[key]
        elsif RBatch.common_config != nil \
          && RBatch.common_config["log_" + key.to_s]
          # use config
          @opt[key] = RBatch.common_config["log_" + key.to_s]
        else
          # use default
        end
      end
      puts "option = " + @opt.to_s if @@verbose
      # determine log file name
      file = @opt[:name]
      file.gsub!("<date>", Time.now.strftime("%Y%m%d"))
      file.gsub!("<time>", Time.now.strftime("%H%M%S"))
      file.gsub!("<prog>", Pathname(File.basename(RBatch.program_name)).sub_ext("").to_s)
      path = File.join(@opt[:dir],file)
      # create Logger instance
      puts "Logfile Path = " + path if @@verbose
      if @opt[:append] && File.exist?(path)
        log = Logger.new(open(path,"a"))
      else
        log = Logger.new(open(path,"w"))
      end
      begin
        log.formatter = @opt[:formatter] if @opt[:formatter]
        log.level = @@log_level_map[@opt[:level]]
        yield log
      rescue => e
        log.fatal("Caught exception; existing 1")
        log.fatal(e)
        exit 1
      ensure
        log.close
      end
    end
  end
end

