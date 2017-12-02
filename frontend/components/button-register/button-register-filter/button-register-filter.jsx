'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'filter';


class ButtonRegisterFilter extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
    }

    handleClick(e) {
        return this.props.onClick();
    }

    render() {
        return <Button
            ref="btnFilter"
            value = 'Filter'
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref = 'image' src={styles.icons[ICON]}/>
        </Button>
    }
}

/*
ButtonRegisterFilter.propTypes = {
    onClick: PropTypes.func.isRequired
}
*/

ButtonRegisterFilter.defaultProps = {
    disabled: false,
    show: true
};
module.exports = ButtonRegisterFilter;