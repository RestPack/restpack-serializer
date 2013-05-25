require './spec/spec_helper'

describe RestPack::Serializer::SideLoading do
  context "invalid :includes" do
    before(:each) do
      FactoryGirl.create(:song)
    end

    context "an include to an inexistent model" do
      it "raises an exception" do
        exception = RestPack::Serializer::InvalidInclude
        message = ":wrong is not a valid include for Song"

        expect do
          SongSerializer.side_loads([Song.first], RestPack::Serializer::Options.new(Song, { "includes" => "wrong" }))
        end.to raise_error(exception, message)
      end
    end

    context "an include to a model which has not been whitelisted with 'can_include'" do
      it "raises an exception" do
        payment = FactoryGirl.create(:payment)
        exception = RestPack::Serializer::InvalidInclude
        message = ":payments is not a valid include for Artist"

        expect do
          ArtistSerializer.side_loads([payment.artist], RestPack::Serializer::Options.new(Artist, { "includes" => "payments" }))
        end.to raise_error(exception, message)
      end
    end
  end

  describe "#can_include" do
    class CustomSerializer
      include RestPack::Serializer
      attributes :a, :b, :c
    end
    it "defaults to empty array" do
      CustomSerializer.can_includes.should == []
    end

    it "allows includes to be specified" do
      class CustomSerializer
        can_include :model1
        can_include :model2, :model3
      end

      CustomSerializer.can_includes.should == [:model1, :model2, :model3]
    end
  end

  describe "#links" do
    AlbumSerializer.links.should == {
      "albums.artist" => {
        :href => "/artists/{albums.artist}.json",
        :type => :artists
      },
      "albums.songs" => {
        :href => "/songs.json?album_id={albums.id}",
        :type => :songs
      }
    }

    it "applies custom RestPack::Serializer.config.href_prefix" do
      original = RestPack::Serializer.config.href_prefix
      RestPack::Serializer.config.href_prefix = "/api/v1"
      AlbumSerializer.links["albums.artist"][:href].should == "/api/v1/artists/{albums.artist}.json"
      RestPack::Serializer.config.href_prefix = original
    end
  end

  describe "#filterable_by" do
    context "a model with no :belongs_to relations" do
      it "is filterable by :id only" do
        ArtistSerializer.filterable_by.should == [:id]
      end
    end
    context "a model with a single :belongs_torelations" do
      it "is filterable by primary key and foreign keys" do
        AlbumSerializer.filterable_by.should =~ [:id, :artist_id]
      end
    end
    context "a model with multiple :belongs_to relations" do
      it "is filterable by primary key and foreign keys" do
        SongSerializer.filterable_by.should =~ [:id, :artist_id, :album_id]
      end
    end
  end
end
