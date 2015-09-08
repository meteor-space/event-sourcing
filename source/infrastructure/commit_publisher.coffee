
class Space.eventSourcing.CommitPublisher

  Dependencies:
    commits: 'Space.eventSourcing.Commits'
    eventBus: 'Space.messaging.EventBus'
    commandBus: 'Space.messaging.CommandBus'

  _isPaused: false
  _queuedCommits: null

  constructor: -> @_queuedCommits = []

  publishCommit: (commit) =>

    if @_isPaused
      @_queuedCommits.push commit
      return

    for event in commit.changes.events
      event.version = commit.version
      @eventBus.publish event

    for command in commit.changes.commands
      @commandBus.send command

    @commits.update commit._id, $set:
      isPublished: true
      publishedAt: new Date()

  pausePublishing: -> @_isPaused = true

  continuePublishing: ->
    @_isPaused = false
    @publishCommit(commit) for commit in @_queuedCommits
    @_queuedCommits = []
