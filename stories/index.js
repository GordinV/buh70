const React = require('react');
const { storiesOf } = require('@storybook/react');
const { action }= require('@storybook/addon-actions');

storiesOf('Button', module)
    .add('with text', () => (
        <button onClick={action('clicked')}>Hello Button</button>
    ))
    .add('with some emoji', () => (
        <button onClick={action('clicked')}>😀 😎 👍 💯</button>;
