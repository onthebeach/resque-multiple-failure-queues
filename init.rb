require 'resque/failure_server'
require 'resque/failure/multiple_failure'

Resque::Failure.backend = Resque::Failure::MultipleFailure