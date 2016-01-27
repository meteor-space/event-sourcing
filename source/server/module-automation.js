Space.Module.mixin({

  routers: [],
  projections: [],

  onDependenciesReady: function() {
    this._wrapLifecycleHook('onInitialize', this._onInitializeEventSourcing);
    this._wrapLifecycleHook('onStart', this._onStartEventSourcing);
  },

  _onInitializeEventSourcing: function(onInitialize) {
    let module = this;
    onInitialize.call(module);
    _.each(_.union(module.routers, module.projections), function(singleton) {
      module.injector.map(singleton).asSingleton();
    });
  },

  _onStartEventSourcing: function(onStart) {
    let module = this;
    onStart.call(module);
    _.each(_.union(module.routers, module.projections), function(singleton) {
      module.injector.create(singleton);
    });
  }

});
