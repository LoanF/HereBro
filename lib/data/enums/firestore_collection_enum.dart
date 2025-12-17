enum FirestoreCollection {
  users('users'),
  contacts('contacts'),
  friendRequests('friend_requests');

  const FirestoreCollection(this.value);

  final String value;
}
