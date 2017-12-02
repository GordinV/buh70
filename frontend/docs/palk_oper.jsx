var React = require('react');
const Form = require('../components/form.js');
const PageLabel = require('../components/page_label');

var pages = ['Page1', 'Page2'];

const Palk = React.createClass({
    render: function() {
        return (
            <Form pages={pages}>
                <span> Palk </span>
            </Form>
        );
    }});

module.exports = Palk;