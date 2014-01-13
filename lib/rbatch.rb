$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'yaml'

module RBatch
  @@ctrl = nil
  module_function
  def init
    @@ctrl = RBatch::Controller.new
  end
  def ctrl ; @@ctrl ; end
  def run_conf ; @@ctrl.run_conf ; end
  def run_conf_path ; @@ctrl.run_conf_path ; end
  def config ; @@ctrl.config ; end
  def common_config ; @@ctrl.common_config ; end
  def cmd(cmd_str,opt = nil)
    RBatch::Cmd.new(run_conf,cmd_str,opt).run
  end
end

# main
require 'rbatch/controller'
require 'rbatch/vars'
require 'rbatch/journal'
require 'rbatch/run_conf'
require 'rbatch/double_run_checker'
require 'rbatch/log'
require 'rbatch/config'
require 'rbatch/cmd'

RBatch::init

