'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'edit';


class ButtonRegisterEdit extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.state = {
            disabled: this.props.disabled
        };
        this.handleClick = this.handleClick.bind(this);
    }

    handleClick(e) {
        return this.props.onClick(this.props.value);
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.disabled !== prevState.disabled) {
            return {disabled: nextProps.disabled};
        } else return null;
    }


    render() {

        let btnStyle = Object.assign({}, styles.buttonEdit, this.props.style ? this.props.style : {});

        return <Button
            value={this.props.value}
            ref="btnEdit"
            style={btnStyle}
            show={this.props.show}
            disabled={this.state.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref='image' src={styles.icons[ICON]}/>
        </Button>
    }
}

/*
ButtonRegisterEdit.propTypes = {
    onClick: PropTypes.func.isRequired,
    disabled: PropTypes.bool
}
*/

ButtonRegisterEdit.defaultProps = {
    disabled: false,
    show: true,
    value: 'Edit'
};

module.exports = ButtonRegisterEdit;