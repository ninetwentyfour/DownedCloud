class Download
  module Views
    class Layout < Mustache
      def title 
        @title || "Trust the Stache"
      end
      def notification 
        @notification || ""
      end
    end
  end
end
