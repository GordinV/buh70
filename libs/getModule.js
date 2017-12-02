const moduleLocator = require('./../libs/moduleLocator.js')();
const path = require('path');
const config = require('../config/documents');

module.exports = (docTypeId, params, modelPath) => {

    let moduleInstance;

    try {
        moduleInstance = moduleLocator.get(docTypeId);

        if (!moduleInstance) {
            // will return the instance of the model
            let folder,
                doc = docTypeId.toLowerCase();

            folder = path.join(modelPath, config[doc]);

            //module exist, we can register it
            moduleLocator.register(docTypeId, require(folder));
            moduleInstance = moduleLocator.get(docTypeId)
        }

    }
    catch (e) {
//        console.error('Error',e);
        return null;
    }

    return moduleInstance;

};
