module HasEntered
  extend ActiveSupport::Concern

  included do
    before_create :set_entered
    
    private 
    
    def set_entered
      self.entered = Time.zone.now
    end
  end
  
end
