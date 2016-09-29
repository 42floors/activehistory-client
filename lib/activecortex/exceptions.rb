module ActiveCortex
  
  class Exception < ::Exception
    
    class BadGateway < ActiveCortex::Exception
    end

    class BadRequest < ActiveCortex::Exception
    end

    class Unauthorized < ActiveCortex::Exception
    end

    class NotFound < ActiveCortex::Exception
    end

    class Gone < ActiveCortex::Exception
    end

    class MovedPermanently < ActiveCortex::Exception
    end

    class ApiVersionUnsupported < ActiveCortex::Exception
    end

    class ServiceUnavailable < ActiveCortex::Exception
    end

  end
  
end

