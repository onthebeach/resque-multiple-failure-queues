require 'resque'

module Resque
  module FailureServer
    VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')
    
    def self.registered(app)
      app.get '/failed/list' do
        @queues = Resque::Failure.backend.queues
        failures_view(:failures)
      end
      
      app.get '/failed/:queue' do
        @start = params[:start].to_i || 0
        @failed = Resque::Failure.backend.all(params[:queue], @start, 20)
        failures_view(:failure_queue)
      end
      
      app.post '/failed/:queue/clear' do
        Resque::Failure.backend.clear(params[:queue])
        redirect u("failures/#{params[:queue]}")
      end
      
      app.get '/failed/:queue/requeue/:id' do
        Resque::Failure.backend.requeue(params[:queue], params[:id])
        if request.xhr?
          return Resque::Failure.backend.all(params[:queue], params[:index])['retried_at']
        else
          redirect u("failure/#{params[:queue]}")
        end
      end
      
      app.helpers do
        def failures_view(filename, options = {}, locals = {})
          erb(File.read(File.join(::Resque::FailureServer::VIEW_PATH, "#{filename}.erb")), options, locals)
        end
      end
    end
    
  end
end

Resque::Server.register Resque::FailureServer