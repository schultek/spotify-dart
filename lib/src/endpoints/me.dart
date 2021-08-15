// Copyright (c) 2019, chances, rinukkusu. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of spotify;

class Me extends EndpointPaging {
  @override
  String get _path => 'v1/me';

  Me(SpotifyApiBase api) : super(api);

  Future<User> get() async {
    var jsonString = await _api._get(_path);
    var map = json.decode(jsonString);

    return User.fromJson(map);
  }

  /// Endpoint /v1/me/following only supports "artist" type at the moment.
  /// needs 'user-follow-read' scope
  CursorPages<Artist> following(FollowingType type, [String after = '']) {
    // since 'artists' is the container, there is no
    // containerParse necessary. Adding json to make the
    // CursorPages-Object happy.
    return _getCursorPages('$_path/following?type=${type.key}',
        (json) => Artist.fromJson(json), 'artists', (json) => json);
  }

  /// Get the object currently being played on the user’s Spotify account.
  Future<Player> currentlyPlaying() async {
    var jsonString = await _api._get('$_path/player/currently-playing');

    if (jsonString.isEmpty) {
      return Player();
    }

    var map = json.decode(jsonString);
    return Player.fromJson(map);
  }

  /// Get tracks from the current user’s recently played tracks.
  /// Note: Currently doesn’t support podcast episodes.
  Future<Iterable<PlayHistory>> recentlyPlayed(
      {int? limit, DateTime? after, DateTime? before}) async {
    assert(after == null || before == null,
        'Cannot specify both after and before.');

    final jsonString = await _api._get('$_path/player/recently-played?' +
        _buildQuery({
          'limit': limit,
          'after': after?.millisecondsSinceEpoch,
          'before': before?.millisecondsSinceEpoch
        }));
    final map = json.decode(jsonString);
    return map['items'].map<PlayHistory>((item) => PlayHistory.fromJson(item));
  }

  /// Toggle Shuffle For User's Playback.
  ///
  /// Use [state] to toggle the shuffle. [true] to turn shuffle on and [false]
  /// to turn it off respectively.
  /// Returns the current player state by making another request.
  /// See [player([String market])];
  Future<Player> shuffle(bool state, [String deviceId]) async {
    return _api
        ._put('v1/me/player/shuffle?' +
            _buildQuery({'state': state, 'deviceId': deviceId}))
        .then((response) {
      if (response.isNotEmpty) {
        // the success response of shuffle is always empty, therefore
        // a non-empty response has to be an error
        return Future.error(SpotifyError.fromJson(json.decode(response)));
      }
      return player();
    });
  }

  Future<Player> player([String market]) async {
    var jsonString =
        await _api._get('v1/me/player?' + _buildQuery({'market': market}));
    final map = json.decode(jsonString);
    return Player.fromJson(map);
  }

  Future<Player> play() async {
    var jsonString = await _api._put('$_path/player/play');

    var map = json.decode(jsonString);
    return Player.fromJson(map);
  }

  Future<Player> pause({String deviceId}) async {
    var jsonString = await _api._put('$_path/player/pause?' +
        _buildQuery({
          'deviceId': deviceId,
        }));

    var map = json.decode(jsonString);
    return Player.fromJson(map);
  }

  /// Get the current user's top tracks.
  Future<Iterable<Track>> topTracks() async {
    var jsonString = await _api._get('$_path/top/tracks');
    var map = json.decode(jsonString);

    var items = map['items'] as Iterable<dynamic>;
    return items.map((item) => Track.fromJson(item));
  }

  /// Get the current user's top artists.
  Future<Iterable<Artist>> topArtists() async {
    var jsonString = await _api._get('$_path/top/artists');
    var map = json.decode(jsonString);

    var items = map['items'] as Iterable<dynamic>;
    return items.map((item) => Artist.fromJson(item));
  }

  /// Get information about a user’s available devices.
  Future<Iterable<Device>> devices() async {
    return _api._get('$_path/player/devices').then(_parseDeviceJson);
  }

  /// Get a list of shows saved in the current Spotify user’s library.
  Pages<Show> savedShows() {
    return _getPages('$_path/shows', (json) => Show.fromJson(json['show']));
  }

  Iterable<Device> _parseDeviceJson(String jsonString) {
    var map = json.decode(jsonString);

    var items = map['devices'] as Iterable<dynamic>;
    return items.map((item) => Device.fromJson(item));
  }
}

class FollowingType {
  final String _key;

  const FollowingType(this._key);

  String get key => _key;

  static const artist = FollowingType('artist');
}
