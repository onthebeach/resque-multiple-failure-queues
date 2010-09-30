module Resque
  module Failure
    class MultipleFailure < Base
      def save
        data = {
          :failed_at => Time.now.strftime("%Y/%m/%d %H:%M:%S"),
          :payload   => payload,
          :exception => exception.class.to_s,
          :error     => exception.to_s,
          :backtrace => Array(exception.backtrace),
          :worker    => worker.to_s,
          :queue     => queue
        }
        data = Resque.encode(data)
        Resque.redis.rpush("failed_#{queue}".to_sym, data)
      end
      
      def self.queues
        Resque.queues.map {|queue| "failed_#{queue}"}
      end
      
      def self.count(queue=nil)
        if queue
          queue = queue =~ /^failed_/ ? queue : "failed_#{queue}"
          Resque.redis.llen(queue.to_sym).to_i
        else
          count = 0
          Resque.queues.each do |queue|
            count += Resque.redis.llen("failed_#{queue}".to_sym).to_i
          end
          count
        end
      end
      
      def self.url
        "/failed/list"
      end
      
      def self.all(queue, start = 0, count = 1)
        queue = queue =~ /^failed_/ ? queue : "failed_#{queue}"
        Resque.list_range(queue.to_sym, start, count)
      end

      def self.clear(queue=nil)
        if queue
          queue = queue =~ /^failed_/ ? queue : "failed_#{queue}"
          Resque.redis.del(queue.to_sym)
        else
          Resque.queues.each {|queue| Resque.redis.del("failed_#{queue}") }
        end
      end

      def self.requeue(queue, index)
        queue = queue =~ /^failed_/ ? queue : "failed_#{queue}"
        item = all(queue, index)
        item['retried_at'] = Time.now.strftime("%Y/%m/%d %H:%M:%S")
        Resque.redis.lset(queue.to_sym, index, Resque.encode(item))
        Job.create(item['queue'], item['payload']['class'], *item['payload']['args'])
      end
    end
  end
end