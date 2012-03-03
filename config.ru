$:.unshift(__FILE__, ".")

require 'download'

use Rack::ShowExceptions

run Download.new