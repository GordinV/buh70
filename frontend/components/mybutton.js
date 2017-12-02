
var React = require('react');

var MyButton = React.createClass({
    displayName: 'MyButton',


    render: function render() {
        return React.createElement('input', {
            className:this.props.className,
            type: 'button',
            value: this.props.buttonValue,
            disabled:this.props.disabled,
            onClick: this.handleButtonClick });
    },

    handleButtonClick: function handleButtonClick() {
        // вернем в обработчик состояний событие клик
        this.props.onClick();
    }
});

module.exports = MyButton;
