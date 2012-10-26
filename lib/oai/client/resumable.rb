module OAI
  module Resumable

    class ResumptionWrapper
      include Enumerable

      def initialize(response)
        @response = response
        @resumption_block = response.resumption_block
      end

      def each(&block)
        yield_from_response &block
        while resumable?
          @response = @resumption_block.call @response
          yield_from_response &block
        end
      end

      private

      def yield_from_response(&block)
        @response.each do |obj|
          block.call(obj)
        end
      end

      def resumable?
        @response.resumption_token and not @response.resumption_token.empty?
      end

    end

    def full
      if @resumption_block.nil?
        raise NotImplementedError.new("Resumption block not provided")
      end
      ResumptionWrapper.new(self)
    end

  end
end
