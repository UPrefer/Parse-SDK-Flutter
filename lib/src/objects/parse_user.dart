part of flutter_parse_sdk;

class ParseUser extends ParseBase implements ParseCloneable {

  ParseUser.clone(Map map): this(map[keyVarUsername],map[keyVarPassword],map[keyVarEmail]);

  @override
  clone(Map map) => ParseUser.clone(map)..fromJson(map);

  static final String path = "$keyEndPointClasses$keyClassUser";

  bool _debug;
  ParseHTTPClient _client;

  Map get acl => super.get<Map>(keyVarAcl);
  set acl(Map acl) => set<Map>(keyVarAcl, acl);

  String get username => super.get<String>(keyVarUsername);
  set username(String username) => set<String>(keyVarUsername, username);

  String get password => super.get<String>(keyVarPassword);
  set password(String password) => set<String>(keyVarPassword, password);

  String get emailAddress => super.get<String>(keyVarEmail);
  set emailAddress(String emailAddress) => set<String>(keyVarEmail, emailAddress);

  /// Creates an instance of ParseUser
  ///
  /// Users can set whether debug should be set on this class with a [bool],
  /// they can also create thier own custom version of [ParseHttpClient]
  ///
  /// Creates a new user locally
  ///
  /// Requires [String] username, [String] password. [String] email address
  /// is required as well to create a full new user object on ParseServer. Only
  /// username and password is required to login
  ParseUser(String username, String password, String emailAddress, {bool debug, ParseHTTPClient client}) : super() {
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(objectLevelDebug: debug);

    this.username = username;
    this.password = password;
    this.emailAddress = emailAddress;

    setClassName(keyClassUser);
  }

  create(String username, String password, [String emailAddress]) {
    return ParseUser(username, password, emailAddress);
  }

  /// Gets the current user from the server
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  getCurrentUserFromServer() async {
    // We can't get the current user and session without a sessionId
    if (_client.data.sessionId == null) return null;

    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri uri = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$keyEndPointUserName");

      final response = await _client
          .get(uri, headers: {keyHeaderSessionToken: _client.data.sessionId});
      return _handleResponse(response, ParseApiRQ.currentUser);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.currentUser);
    }
  }
  /// Gets the current user from storage
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  static currentUser() {
    return _getUserFromLocalStore();
  }

  /// Registers a user on Parse Server
  ///
  /// After creating a new user via [Parse.create] call this method to register
  /// that user on Parse
  signUp() async {
    try {
      if (emailAddress == null) return null;

      Map<String, dynamic> bodyData = {};
      bodyData[keyVarEmail] = emailAddress;
      bodyData[keyVarPassword] = password;
      bodyData[keyVarUsername] = username;

      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$path");

      final response = await _client.post(url,
          headers: {
            keyHeaderRevocableSession: "1",
          },
          body: JsonEncoder().convert(bodyData));

      _handleResponse(response, ParseApiRQ.signUp);
      return this;
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.signUp);
    }
  }

  /// Logs a user in via Parse
  ///
  /// Once a user is created using [Parse.create] and a username and password is
  /// provided, call this method to login.
  login() async {
    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$keyEndPointLogin",
          queryParameters: {keyVarUsername: username, keyVarPassword: password});

      final response = await _client.post(url, headers: {
        keyHeaderRevocableSession: "1",
      });

      _handleResponse(response, ParseApiRQ.login);
      return this;
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.login);
    }
  }

  /// Removes the current user from the session data
  logout() {
    _client.data.sessionId = null;
    setObjectData(null);
  }

  /// Sends a verification email to the users email address
  verificationEmailRequest() async {
    try {
      final response = await _client.post(
          "${_client.data.serverUrl}$keyEndPointVerificationEmail",
          body: JsonEncoder().convert({keyVarEmail: emailAddress}));

      return _handleResponse(response, ParseApiRQ.verificationEmailRequest);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.verificationEmailRequest);
    }
  }

  /// Sends a password reset email to the users email address
  requestPasswordReset() async {
    try {
      final response = await _client.post(
          "${_client.data.serverUrl}$keyEndPointRequestPasswordReset",
          body: JsonEncoder().convert({keyVarEmail: emailAddress}));
      return _handleResponse(response, ParseApiRQ.requestPasswordReset);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.requestPasswordReset);
    }
  }

  /// Saves the current user
  ///
  /// If changes are made to the current user, call save to sync them with
  /// Parse Server
  save() async {
    if (objectId == null) {
      return signUp();
    } else {
      try {
        Map map = toJson(forApiRQ: true);
        final response = await _client.put(
            _client.data.serverUrl + "$path/$objectId",
            body: map);
        return _handleResponse(response, ParseApiRQ.save);
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.save);
      }
    }
  }

  /// Removes a user from Parse Server locally and online
  Future<ParseResponse> destroy() async {
    if (objectId != null) {
      try {
        final response = await _client.delete(
            _client.data.serverUrl + "$path/$objectId",
            headers: {keyHeaderSessionToken: _client.data.sessionId});
        return _handleResponse(response, ParseApiRQ.destroy);
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.destroy);
      }
    }

    return null;
  }

  /// Gets a list of all users (limited return)
  static Future<ParseResponse> all() async {

    var emptyUser = ParseUser(null, null, null);

    try {
      final response = await ParseHTTPClient().get(
          "${ParseCoreData().serverUrl}/$path");

      ParseResponse parseResponse = ParseResponse.handleResponse(emptyUser, response);

      if (ParseCoreData().debug) {
        logger(ParseCoreData().appName, keyClassUser, ParseApiRQ.getAll.toString(), parseResponse);
      }

      return parseResponse;
    } on Exception catch (e) {
      return ParseResponse.handleException(e);
    }
  }

  static ParseUser _getUserFromLocalStore() {
    var userJson = ParseCoreData().getStore().getString(keyParseStoreUser);

    if (userJson != null) {
      var userMap = JsonDecoder().convert(userJson);

      if (userMap != null) {
        ParseCoreData().sessionId = userMap[keyParamSessionToken];
        return ParseUser.clone(userMap);
      }
    }

    return null;
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  ParseResponse _handleException(Exception exception, ParseApiRQ type) {
    ParseResponse parseResponse = ParseResponse.handleException(exception);

    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }

  /// Handles all the response data for this class
  _handleResponse(Response response, ParseApiRQ type) {

    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);
    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);
    if (responseData.containsKey(keyVarObjectId)) {
      fromJson(responseData);
      _client.data.sessionId = responseData[keyParamSessionToken];
    }

    if (type == ParseApiRQ.getAll || type == ParseApiRQ.destroy) {
      return parseResponse;
    } else {
      saveInStorage(keyParseStoreUser);
      return this;
    }
  }
}