
{ValueObject} = Space.cqrs

describe 'Space.cqrs.ValueObject', ->

  class Quantity extends ValueObject
    @fields:
      value: Match.Integer

  it 'is serializable', ->
    expect(ValueObject).to.extend Space.messaging.Serializable

  it 'freezes after creation', ->

    quantity = new Quantity value: 2
    quantity.value = 4
    expect(quantity.value).to.equal 2

  it 'doesnt freeze if the API is not supported', ->

    freezeBackup = Object.freeze
    Object.freeze = null
    quantity = new Quantity value: 2
    quantity.value = 4
    expect(quantity.value).to.equal 4
    Object.freeze = freezeBackup
