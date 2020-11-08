'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    Button = require('../button-register/button-register.jsx'),
    buttonStyles = require('../button-register/button-register-styles'),
    styles = require('./modalpage-styles');

class ModalPage extends React.PureComponent {
    constructor(props) {
        super(props);
        this.handleBtnClick.bind(this);
        this.changeVisibilityModalPage.bind(this);
        this.state = {
            show: this.props.show
        };
        this.onKeyUp = this.onKeyUp.bind(this);
    }

    changeVisibilityModalPage() {
        this.setState({show: !this.state.show});
    }

    // will update state if props changed

    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.show !== prevState.show) {
            return {show: nextProps.show};
        } else return null;
    }


    handleBtnClick(btnEvent) {
        // закрываем окно и если передан обработчик, отдаем туда данные

        this.changeVisibilityModalPage();
        if (this.props.modalPageBtnClick) {
            let show = this.props.modalPageBtnClick(btnEvent);
        }

    }

    /**
     * перехватит сыбтия нажатия кнопки и вызовет дефолтные методы
     * @param e
     */
    onKeyUp(e) {
        switch (e.key) {
            case 'Enter':
                if (this.refs['btnOk']) {
                    this.handleBtnClick('Ok');
                }
                break;
            case 'Escape':
                if (this.refs['btnCancel']) {
                    this.handleBtnClick('Cancel');
                }
                break;
        }
    }

    render() {
        // если передан атрибу modalObjects = ['btnOk','btnCancel']
        let hideBtnOk = this.props.modalObjects.indexOf('btnOk') == -1 ? false : true, // управление кнопкой Ок
            hideBtnCancel = this.props.modalObjects.indexOf('btnCancel') == -1 ? false : true, // управление кнопкой Cancel
            displayModal = this.state.show ? 'flex' : 'none',
            pagePosition = this.props.position,
            containerStyle = Object.assign({}, styles.container, {display: displayModal}, {justifyContent: pagePosition}),
            buttonOkStyle = Object.assign({}, styles.modalPageButtons, styles.defaultButton);

        const Style = Object.assign({}, styles.modalPage, this.props.styles ? this.props.styles : {});

        return (
            <div
                ref="container"
                style={containerStyle}
                onKeyUp={this.onKeyUp}
            >
                <div style={Style} ref='modalPageContainer'>
                    <div style={styles.header} ref='modalPageHeader'>
                        <span ref='headerName' style={styles.headerName}> {this.props.modalPageName} </span>
                        <Button style={styles.buttonClose} ref="btnClose"
                                onClick={this.changeVisibilityModalPage.bind(this)} value="x"/>
                    </div>
                    <div style={styles.modalPageContent} ref="modalPageContent">
                        {this.props.children}
                    </div>

                    <div style={styles.modalFooter} ref='modalPageButtons'>
                        {hideBtnOk ?
                            <Button
                                ref="btnOk"
                                value="Ok"
                                style={buttonOkStyle}
                                width={('width' in styles.modalPageButtons) ? styles.modalPageButtons.width : null}
                                height={('height' in styles.modalPageButtons) ? styles.modalPageButtons.height : null}
                                onClick={this.handleBtnClick.bind(this, 'Ok')}
                                id='btnOk'>
                                <img ref="image" src={buttonStyles.icons['ok']}/>
                            </Button> : null
                        }
                        <div style={styles.buttonsSeparator}></div>
                        {hideBtnCancel ?
                            <Button
                                ref="btnCancel"
                                value="Cancel"
                                style={styles.modalPageButtons}
                                width={('width' in styles.modalPageButtons) ? styles.modalPageButtons.width : null}
                                height={('height' in styles.modalPageButtons) ? styles.modalPageButtons.height : null}
                                onClick={this.handleBtnClick.bind(this, 'Cancel')}
                                className='modalPageButtons'
                                id='btnCancel'>
                                <img ref="image" src={buttonStyles.icons['cancel']}/>
                            </Button> : null
                        }
                    </div>
                </div>
            </div>
        )
    }
}

/*
ModalPage.propTypes = {
    modalPageName: PropTypes.string.isRequired,
    modalPageBtnClick: PropTypes.func.isRequired,
    show: PropTypes.bool,
    position: PropTypes.oneOf(['center', 'flex-start', 'flex-end']),
}
*/

ModalPage.defaultProps = {
    modalPageName: 'defaulName',
    modalObjects: ['btnOk', 'btnCancel'],
    position: 'center',
    show: false
};

module.exports = ModalPage;