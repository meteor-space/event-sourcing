
class Space.eventSourcing.CommitPublisher

  Dependencies:
    commits: 'Space.eventSourcing.Commits'
    eventBus: 'Space.messaging.EventBus'
    commandBus: 'Space.messaging.CommandBus'

  publishCommit: (commit) =>

    for event in commit.changes.events
      event.version = commit.version
      @eventBus.publish event

    for command in commit.changes.commands
      @commandBus.send command

    @commits.update commit._id, $set:
      isPublished: true
      publishedAt: new Date()
