'use strict';

const React = require('react');
;
const PropTypes = require('prop-types');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'login';


class ButtonLogin extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);

        this.state = {
            value: props.value || 'LogIn'
        }

    }

    componentWillReceiveProps(nextProps) {
        this.setState({value: nextProps.value});
    }

    handleClick(e) {
        return this.props.onClick('login');
    }

    render() {
        let value = this.state.value;

        return <Button
            value={value}
            ref="btnLogin"
            style={styles.button}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}
;


ButtonLogin.propTypes = {
    onClick: PropTypes.func.isRequired,
    value: PropTypes.string
}


ButtonLogin.defaultProps = {
    disabled: false,
    show: true,
    value: 'LogOut'
};

module.exports = ButtonLogin;