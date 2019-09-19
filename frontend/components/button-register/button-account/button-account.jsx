'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'account';


class ButtonAccount extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);

        this.state = {
            value: props.value
        }

    }


    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value) {
            return {value: nextProps.value};
        } else return null;
    }

    handleClick() {
        return this.props.onClick('account');
    }

    render() {
        let value = this.state.value;
        let buttonStyle = Object.assign({},styles.button,styles.buttonAccount);
        return <Button
            value={value}
            ref="btnAccount"
            style={buttonStyle}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}



ButtonAccount.propTypes = {
    onClick: PropTypes.func.isRequired,
    value: PropTypes.string
};


ButtonAccount.defaultProps = {
    disabled: false,
    show: true,
    value: ''
};

module.exports = ButtonAccount;