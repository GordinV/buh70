var React = require('react'),
    flux = require('fluxify');

const PageLabel = require('./page_label');

const Form = React.createClass({
    displayName: 'Form',

    getInitialState: function getInitialState() {
        var pages = [{pageName: 'Page'}];
        if (this.props.pages) {
            pages = this.props.pages;
        }
        return {
            pages: this.props.pages
        };
    },

    render: function render() {
        var pages = this.state.pages;
        return React.createElement(
            'div',
            { className: 'container' },
            pages.map(function (page, idx) {
                return React.createElement(
                    PageLabel,
                    { key:idx, pageIdx: idx },
                    page
                );
            }),
            React.createElement(
                'div',
                { className: 'page' },
                React.createElement(
                    'form',
                    null,
                    this.props.children
                )
            )
        );
    }
});

module.exports = Form;