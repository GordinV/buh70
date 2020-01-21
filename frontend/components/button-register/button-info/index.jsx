'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'info';

const DocContext = require('./../../../doc-context.js');

class ButtonInfo extends React.Component {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
    }

    /**
     * обработчик события клик, откроет модальное окно
     * @param e
     */
    handleClick() {
        let docTypeId = this.props.docTypeId ?  this.props.docTypeId: DocContext.docTypeId;
        let url = `/help/${docTypeId}`;
        window.open(`${url}`);
    }

    render() {
        return (
            <div>
                <Button
                    ref="btnInfo"
                    value={this.props.value}
                    show={this.props.show}
                    disabled={this.props.disabled}
                    onClick={this.handleClick}>
                    <img ref='image' src={styles.icons[ICON]}/>
                </Button>
            </div>
        )
    }

}

/*
ButtonRegisterPrint.propTypes = {
    onClick: PropTypes.func.isRequired
}
*/

ButtonInfo.defaultProps = {
    disabled: false,
    show: true,
    value: ''
};

module.exports = ButtonInfo;