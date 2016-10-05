module ActiveHistory
  
  class Exception < ::Exception
    
    class BadGateway < ActiveHistory::Exception
    end

    class BadRequest < ActiveHistory::Exception
    end

    class Unauthorized < ActiveHistory::Exception
    end

    class NotFound < ActiveHistory::Exception
    end

    class Gone < ActiveHistory::Exception
    end

    class MovedPermanently < ActiveHistory::Exception
    end

    class ApiVersionUnsupported < ActiveHistory::Exception
    end

    class ServiceUnavailable < ActiveHistory::Exception
    end

  end
  
end

