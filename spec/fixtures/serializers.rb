class SongSerializer
  include RestPack::Serializer
  attributes :id, :title, :album_id
end

class AlbumSerializer
  include RestPack::Serializer
  attributes :id, :title, :year, :artist_id
end

class ArtistSerializer
  include RestPack::Serializer
  attributes :id, :name, :website
end