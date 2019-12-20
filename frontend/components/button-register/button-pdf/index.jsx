'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'attachment';


class ButtonPdf extends React.PureComponent {
// кнопка вызова файла влодения в формате PDF
    constructor(props) {
        super(props);
    }

    handleClick(e) {
        if (this.props.onClick()) {
            return this.props.onClick();
        }
    }

    render() {
        return <Button
            ref="btnGetPdf"
            value = {this.props.value? this.props.value: 'PDF'}
            onClick={(e) => this.handleClick(e)}>
            <img ref = 'image' src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonPdf.defaultProps = {
    disabled: false,
    show: true
};
module.exports = ButtonPdf;