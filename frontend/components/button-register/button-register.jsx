'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const styles = require('./button-register-styles');


class Button extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
        this.state = {
            disabled: this.props.disabled
        }
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.disabled !== prevState.disabled) {
            return {disabled: nextProps.disabled};
        } else return null;
    }

    handleClick(event) {
        switch (event.type) {
            case 'click':
                this.props.onClick(this.props.value);
                break;
            case 'dblclick':
                this.props.onClick(this.props.value);
                break;
            default:
                console.log('unhandled', event.type);
        }
    }

    render() {
        // visibility
        let visibility = this.props.show ? 'initial' : 'hidden';

        let propStyle  = ('style' in this.props)? this.props.style: {},
            style = Object.assign({}, styles.button, propStyle, {visibility: visibility});


        return <button
            disabled={this.state.disabled}
            ref="button"
            style={style}
            onDoubleClick={this.handleClick}
            onClick={this.handleClick}>
            {this.props.children}
            {this.props.value}
        </button>
    }
}

Button.propTypes = {
    onClick: PropTypes.func.isRequired,
    value: PropTypes.string.isRequired,
    style: PropTypes.object
};



Button.defaultProps = {
    disabled: false,
    show: true
};

module.exports = Button;