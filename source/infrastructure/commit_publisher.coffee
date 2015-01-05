
class Space.cqrs.CommitPublisher

  @toString: -> 'Space.cqrs.CommitPublisher'

  Dependencies:
    commits: 'Space.cqrs.CommitCollection'
    eventBus: 'Space.cqrs.EventBus'
    commandBus: 'Space.cqrs.CommandBus'

  publishCommit: (commit) =>

    for event in commit.changes.events
      event.version = commit.version
      @eventBus.publish event

    for command in commit.changes.commands
      @commandBus.send command

    @commits.update commit._id, $set: isPublished: true
