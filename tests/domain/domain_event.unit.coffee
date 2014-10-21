
DomainEvent = Space.cqrs.DomainEvent

describe "#{DomainEvent}", ->

  class MyEvent
    @toString: -> 'MyEvent'

  beforeEach ->

    @params = {
      type: MyEvent
      sourceId: 'test'
      data: {}
      version: 0
    }

  it 'saves references of required params', ->

    event = new DomainEvent @params

    expect(event.type).to.equal MyEvent.toString()
    expect(event.sourceId).to.equal @params.sourceId
    expect(event.data).to.equal @params.data
    expect(event.version).to.equal @params.version

  it 'requires a params object', ->
    expect(-> new DomainEvent()).to.throw DomainEvent.PARAMS_REQUIRED_ERROR

  it 'requires an event type', ->
    delete @params.type
    expect(=> new DomainEvent(@params)).to.throw DomainEvent.EVENT_TYPE_REQUIRED_ERROR

  it 'requires a source id', ->
    delete @params.sourceId
    expect(=> new DomainEvent(@params)).to.throw DomainEvent.SOURCE_ID_REQUIRED_ERROR

  it 'sets data to empty object if none given', ->
    delete @params.data
    event = new DomainEvent @params
    expect(event.data).to.eql {}

  it 'sets version to null if not provided', ->
    delete @params.version
    event = new DomainEvent @params
    expect(event.version).to.equal 0