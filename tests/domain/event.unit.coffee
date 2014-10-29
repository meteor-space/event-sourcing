
Event = Space.cqrs.Event

describe "#{Event}", ->

  class MyEvent
    @toString: -> 'MyEvent'

  beforeEach ->

    @params = {
      type: MyEvent.toString()
      sourceId: 'test'
      data: {}
      version: 0
    }

  it 'saves references of required params', ->

    event = new Event @params

    expect(event.type).to.equal MyEvent.toString()
    expect(event.sourceId).to.equal @params.sourceId
    expect(event.data).to.equal @params.data
    expect(event.version).to.equal @params.version

  it 'requires a params object', ->
    expect(-> new Event()).to.throw Event.PARAMS_REQUIRED_ERROR

  it 'requires an event type', ->
    delete @params.type
    expect(=> new Event(@params)).to.throw Event.EVENT_TYPE_REQUIRED_ERROR

  it 'requires a source id', ->
    delete @params.sourceId
    expect(=> new Event(@params)).to.throw Event.SOURCE_ID_REQUIRED_ERROR

  it 'sets data to empty object if none given', ->
    delete @params.data
    event = new Event @params
    expect(event.data).to.eql {}

  it 'sets version to null if not provided', ->
    delete @params.version
    event = new Event @params
    expect(event.version).to.equal null