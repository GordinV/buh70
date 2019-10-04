'use strict';

const DocContext = require('../../doc-context');

const PropTypes = require('prop-types');
const {withRouter} = require('react-router-dom');
const fetchData = require('./../../../libs/fetchData');
const _ = require('lodash');


const React = require('react'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    BtnStart = require('./../button-register/button-register-start/button-register-start.jsx'),
    BtnLogin = require('./../button-register/button-login/button-login.jsx'),
    StartMenu = require('./../start-menu/start-menu.jsx'),
    SelectRekv = require('./../select-rekv/index.jsx'),
    BtnAccount = require('./../button-register/button-account/button-account.jsx');

const style = require('./menu-toolbar.styles');

class MenuToolBar extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            logedIn: true,
            startMenuValue: 'parentid',
            showStartMenu: false,
            isOpenRekvPage: false
        };


        this.btnStartClick = this.btnStartClick.bind(this);
        this.btnLoginClick = this.btnLoginClick.bind(this);
        this.renderStartMenu = this.renderStartMenu.bind(this);
        this.startMenuClickHandler = this.startMenuClickHandler.bind(this);
        this.handleChange = this.handleChange.bind(this);

    }

    render() {
        let isEditMode = this.props.edited,
            toolbarParams = {
                btnStart: {
                    show: this.props.params['btnStart'].show || false,
                    disabled: isEditMode
                },
                btnLogin: {
                    show: true,
                    disabled: false
                },
                btnAccount: {
                    show: this.state.logedIn || false,
                    disabled: false
                }
            };

        const selectStyle = {
            margin: '5px',
            display: 'flex',
            width: '95%'
        };

        let userAccessList = [];

        console.log('DocContext.userData',DocContext.userData);
        if (_.has(DocContext.userData, 'userAccessList')) {
             userAccessList = DocContext.userData.userAccessList.map((row) => {
                let rowObject = JSON.parse(row);
                return {id: rowObject.id, kood: '', name: rowObject.nimetus};
            });
        }


        let rekvId = 0 ;
        if (this.state.logedIn && _.has(DocContext.userData,'asutusId')) {
            rekvId =  DocContext.userData.asutusId;
        }

        return (
            <div style={style['container']}>
                <ToolbarContainer
                    ref='menuToolbarContainer'
                    position="left">
                    <BtnStart ref='btnStart'
                              onClick={this.btnStartClick}
                              show={toolbarParams['btnStart'].show}
                              disabled={toolbarParams['btnStart'].disabled}
                    />

                    <SelectRekv name='rekvId'
                                libs="rekv"
                                style={selectStyle}
                                data={userAccessList}
                                readOnly={false}
                                defaultValue={''}
                                value={rekvId}
                                collId='id'
                                ref='rekvId'
                                onChange={this.handleChange}/>

                    <BtnAccount ref='btnAccount'
                                value={DocContext.userData ? DocContext.userData.userName : ''}
                                onClick={this.btnAccountClick}
                                show={toolbarParams['btnAccount'].show}
                                disabled={toolbarParams['btnAccount'].disabled}/>
                    <BtnLogin ref='btnLogin'
                              value={this.state.logedIn ? 'LogOut' : 'LogIn'}
                              onClick={this.btnLoginClick}
                              show={toolbarParams['btnLogin'].show}
                              disabled={toolbarParams['btnLogin'].disabled}/>
                </ToolbarContainer>
                {this.renderStartMenu()}

            </div>
        );
    }

    renderStartMenu() {
        let component;
        if (this.state.showStartMenu) {
            component = <StartMenu ref='startMenu'
                                   module={DocContext.module}
                                   value={this.state.startMenuValue}
                                   userData={DocContext.userData}
                                   clickHandler={this.startMenuClickHandler}/>
        }
        return component
    }

    btnStartClick() {
        // обработчик для кнопки Start

        this.setState({showStartMenu: !this.state.showStartMenu});

    }

    /**
     * получит от стартого меню данные, спрячет меню
     */
    startMenuClickHandler(value) {
        this.setState({showStartMenu: false});
        if (this.props.history) {
            return this.props.history.push({
                pathname: `/${DocContext.module}/${value}`,
                state: {module: DocContext.module}

            });
        } else {
            document.location.href = `/${DocContext.module}/${value}`
        }
    }

    btnLoginClick() {
        const URL = '/logout';
        this.setState({logedIn: false});

        try {
            let userId = DocContext.userData.userId;
            const params = {
                userId: userId, module: DocContext.module,
                uuid: this.state.logedIn ? DocContext.userData.uuid : null
            };

            fetchData.fetchDataPost(URL, params).then(() => {
                    DocContext.userData = null;
                }
            );
        } catch (e) {
            console.error(e);
        }
        document.location.href = '/login';
    }


    btnAccountClick() {
        //@todo Страницу с данными пользователся
        console.log('btnAccount');
    }

    handleChange(inputName, inputValue) {
        const URL = '/newApi/changeAsutus';
        let rekvId = inputValue; // choose asutusId

        if (!this.state.logedIn) {
            return;
        }

        // отправить пост запрос
        try {
            let localUrl = `${URL}/${rekvId}`;
            let userId = this.state.logedIn ? DocContext.userData.userId : null;
            let uuid = this.state.logedIn ? DocContext.userData.uuid : null;

            const params = {userId: userId, module: DocContext.module, uuid: uuid};

            fetchData.fetchDataPost(localUrl, params).then(response => {
                DocContext.userData = Object.assign(DocContext.userData, response.config.data);
                document.location.reload();
            });

        } catch (e) {
            console.error(e);
        }
        // получить и сохрать данные пользователя
        // обновить регистр документов - перейти на главную страницу
    }


}

/*
MenuToolBar
    .propTypes = {
    edited: PropTypes.bool,
    params: PropTypes.object.isRequired,
    logedIn: PropTypes.bool
};


MenuToolBar
    .defaultProps = {
    edited: false,
    logedIn: false,
    params: {
        btnStart: {
            show: true
        }
    }
};
*/

module.exports = withRouter(MenuToolBar);