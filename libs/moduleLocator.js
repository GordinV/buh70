'use strict';

// регистрируем модули (модели)
module.exports = () => {
    const modules = {};

    modules.register = (name, instance) => {
        if (!instance) {
            throw new Error('Cannot find module: ' + name);
        }

        if (!modules[name]) {
            modules[name] = instance;
        }
    }

    modules.get = (name) => {
        return modules[name];
    }

    return modules;
}