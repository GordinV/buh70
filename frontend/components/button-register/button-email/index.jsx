'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ModalPage = require('./../../modalpage/modalPage.jsx'),
    ICON = 'mail';


class ButtonRegisterEmail extends React.Component {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.state = {
            showModal: false
        };
        this.modalPageClick = this.modalPageClick.bind(this);
    }

    /**
     * обработчик события клик, откроет модальное окно
     * @param e
     */
    handleClick(e) {
        // если требуется предварительно ихвещение, то открываем модальное окно, иначе вызываем метод из пропсов
        if (this.props.docTypeId.toLowerCase() === 'arv' || this.props.docTypeId.toLowerCase() === 'teatis') {
            this.setState({showModal: true});
        } else {
            this.modalPageClick('Ok')
        }

    }

    render() {
        return (
            <div>
                <Button
                    ref="btnEmail"
                    value={this.props.value}
                    show={this.props.show}
                    disabled={this.props.disabled}
                    onClick={(e) => this.handleClick(e)}>
                    <img ref='image' src={styles.icons[ICON]}/>
                </Button>
                <ModalPage
                    modalPageBtnClick={this.modalPageClick}
                    modalPageName={`${this.props.value}`}
                    show={this.state.showModal}
                    modalObjects={['btnOk', 'btnCancel']}
                >
                    {`Kas saada email ?`}
                </ModalPage>

            </div>
        )
    }

    /**
     * обработчик на событие клика на кнопки можального окна
     * @param btnEvent
     */
    modalPageClick(btnEvent) {
        if (btnEvent === 'Ok') {
            this.props.onClick(this.props.value);
        }
        this.setState({showModal: false});
    }

}

/*
ButtonRegisterPrint.propTypes = {
    onClick: PropTypes.func.isRequired
}
*/

ButtonRegisterEmail.defaultProps = {
    disabled: false,
    show: true,
    value: 'Email',
    docTypeId:''
};

module.exports = ButtonRegisterEmail;