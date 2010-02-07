require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

class MThingy
  class NThingy
  end
end

describe Dataset::Record::Heirarchy do
  before do
    @heirarchy = Dataset::Record::Heirarchy.new(Place)
  end
  
  describe 'finder name' do
    it 'should collapse single character followed by underscore to just the single character' do      
      @heirarchy.finder_name(MThingy).should == 'mthingy'
      @heirarchy.finder_name(MThingy::NThingy).should == 'mthingy_nthingy'
    end
    
    it 'should not return an empty name for an un-named module' do
      anonymous_module = Module.new
      @heirarchy.finder_name(anonymous_module).should_not == ''
    end
  end
  
  describe 'model finder name' do
    it 'should not throw when called with an un-named module' do
      anonymous_module = Module.new
      @heirarchy.model_finder_name(anonymous_module)
    end
  end
end