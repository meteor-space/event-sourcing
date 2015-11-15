Space.messaging.Serializable.extend(Space.eventSourcing, 'Snapshot', {
  fields() {
    return {
      id: Match.OneOf(String, Guid),
      version: Match.Integer,
      state: Match.OneOf(null, String)
    };
  }
});
