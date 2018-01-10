const {configure} = require('@storybook/react');
const infoAddon = require('@kadira/react-storybook-addon-info');

setAddon(infoAddon);

function loadStories() {
    require('../stories/list')
}

configure(loadStories,module);