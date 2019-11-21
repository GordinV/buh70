'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'settings';


class ButtonSettings extends React.PureComponent{
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this)
    }

    handleClick(e) {
        return this.props.onClick(this.props.value);
    }

    render() {
        return <Button
            value = {this.props.value}
            ref="btnSettings"
            style={styles.button}
            disabled={false}
            onClick={this.handleClick}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonSettings.defaultProps = {
    disabled: false,
    show: true,
    value: 'Settings'
};

module.exports = ButtonSettings;