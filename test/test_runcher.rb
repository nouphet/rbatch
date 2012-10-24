require 'test/unit'
require 'rbatch'

class RuncherTest < Test::Unit::TestCase
  def setup
  end

  def test_cmd_exists
    result = RBatch::cmd "ruby -e 'STDOUT.print 1; STDERR.print 2; exit 0;'"
    assert_equal "1", result.stdout.chomp
    assert_equal "2", result.stderr.chomp
    assert_equal 0, result.status
  end
  def test_cmd_does_not_exist
    assert_raise(Errno::ENOENT){
      RBatch::cmd "not_exist_command"
    }
  end
  def test_stdout_size_greater_than_65534
    result = RBatch::cmd "ruby -e '100000.times{print 0}'"
    assert_equal 100000, result.stdout.chomp.size
    assert_equal "", result.stderr.chomp
    assert_equal 0, result.status
  end
  def test_stdout_size_greater_than_65534_with_status_1
    result = RBatch::cmd "ruby -e '100000.times{print 0}; exit 1'"
    assert_equal 100000, result.stdout.chomp.size
    assert_equal "", result.stderr.chomp
    assert_equal 1, result.status
  end
  def test_status_code_is_1
    result = RBatch::cmd "ruby -e 'STDOUT.print 1; STDERR.print 2; exit 1;'"
    assert_equal "1", result.stdout.chomp
    assert_equal "2", result.stderr.chomp
    assert_equal 1, result.status
  end
  def test_status_code_is_greater_than_256
    returncode = 300
    result = RBatch::cmd  "ruby -e 'STDOUT.print 1; STDERR.print 2; exit #{returncode};'"
    assert_equal "1", result.stdout.chomp
    assert_equal "2", result.stderr.chomp
    case RUBY_PLATFORM
    when /mswin|mingw/
      assert_equal returncode, result.status
    when /cygwin|linux/
      assert_equal returncode % 256, result.status
    end
  end
  def test_to_h
    result = RBatch::cmd "ruby -e 'STDOUT.print 1; STDERR.print 2; exit 1;'"
    assert_equal "1", result.to_h[:stdout]
    assert_equal "2", result.to_h[:stderr]
    assert_equal 1  , result.to_h[:status]
  end
  def test_to_s
    result = RBatch::cmd "ruby -e 'STDOUT.print 1; STDERR.print 2; exit 1;'"
    assert_equal "{:stdout=>\"1\", :stderr=>\"2\", :status=>1}", result.to_s
  end
end
