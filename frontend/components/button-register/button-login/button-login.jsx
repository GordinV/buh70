'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'login';


class ButtonLogin extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);

        this.state = {
            value: props.value || 'Sisse'
        }

    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value) {
            return {value: nextProps.value};
        } else return null;
    }


    handleClick(e) {
        return this.props.onClick('login');
    }

    render() {
        let value = this.state.value;
        let buttonStyle = Object.assign({}, styles.button, styles.buttonLogin);

        return <Button
            value={value}
            ref="btnLogin"
            style={buttonStyle}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonLogin.propTypes = {
    onClick: PropTypes.func.isRequired,
    value: PropTypes.string
};


ButtonLogin.defaultProps = {
    disabled: false,
    show: true,
    value: 'Välju'
};

module.exports = ButtonLogin;