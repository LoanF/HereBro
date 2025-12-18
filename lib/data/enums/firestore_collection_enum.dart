enum FirestoreCollection {
  users('users'),
  contacts('contacts'),
  friendRequests('friend_requests'),
  locationRequests('location_requests'),
  sharedWith('shared_with'),
  tracking('tracking');

  const FirestoreCollection(this.value);

  final String value;
}
