require './spec/spec_helper'

describe RestPack::Serializer::Resource do
  before(:each) do
    @album = FactoryGirl.create(:album_with_songs, song_count: 11)
    @song = @album.songs.first
  end

  let(:resource) { SongSerializer.resource(params) }
  let(:params) { { id: @song.id.to_s } }

  it "returns a resource by id" do
    resource[:songs].count.should == 1
    resource[:songs][0][:id].should == @song.id.to_s
  end

  describe "side-loading" do
    let(:params) { { id: @song.id.to_s, includes: 'albums' } }

    it "includes side-loaded models" do
      resource[:albums].count.should == 1
      resource[:albums].first[:id].should == @song.album.id.to_s
    end

    it "includes the side-loads in the main meta data" do
      resource[:meta][:songs][:includes].should == [:albums]
    end
  end

  describe "missing resource" do
    let(:params) { { id: "-99" } }
    it "returns no resource" do
      resource[:songs].length.should == 0
    end

    #TODO: add specs for jsonapi error format when it has been standardised
    # https://github.com/RestPack/restpack-serializer/issues/27
    # https://github.com/json-api/json-api/issues/7
  end
end
