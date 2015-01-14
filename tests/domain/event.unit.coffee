
Event = Space.cqrs.Event

describe "#{Event}", ->

  beforeEach ->
    @params = sourceId: 'test', data: {}, version: 0
    @event = new Event @params

  it 'is serializable', -> expect(Event).to.extend Space.cqrs.Serializable

  it 'defines its EJSON type correctly', ->
    expect(@event.typeName()).to.equal 'Space.cqrs.Event'

  it 'defines its fields correctly', ->
    expect(Event.fields()).to.eql {
      sourceId: String
      data: Match.Optional(Object)
      version: Match.Optional(Match.Integer)
    }

  it 'assigns its fields as properties', ->
    expect(@event.sourceId).to.equal @params.sourceId
    expect(@event.data).to.equal @params.data
    expect(@event.version).to.equal @params.version

  it 'can be serialized', ->
    parsed = EJSON.parse EJSON.stringify(@event)
    expect(parsed).to.deep.equal @event

  it 'requires params', ->
    expect(-> new Event()).to.throw Event.ERRORS.paramsRequiredError

  it 'requires a source id', ->
    expect(-> new Event {}).to.throw Event.ERRORS.sourceIdRequired

  it 'requires data to be an object', ->
    expect(-> new Event sourceId: '123', data: 'test').to.throw Error

  it 'sets data to empty object if none given', ->
    delete @params.data
    event = new Event @params
    expect(event.data).to.eql {}
