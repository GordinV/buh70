'use strict';

const DocContext = require('../../doc-context');

const PropTypes = require('prop-types');
const {withRouter} = require('react-router-dom');
const fetchData = require('./../../../libs/fetchData');

const React = require('react'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    BtnStart = require('./../button-register/button-register-start/button-register-start.jsx'),
    BtnLogin = require('./../button-register/button-login/button-login.jsx'),
    BtnEdit = require('./../button-register/button-register-edit/button-register-edit.jsx'),
    BtnInfo = require('./../button-register/button-info/index.jsx'),
    BtnLink = require('./../button-register/button-link/index.jsx'),
    StartMenu = require('./../start-menu/start-menu.jsx'),
    SelectRekv = require('./../select-rekv/index.jsx'),
    NoticeButton = require('./../button-register/button_noticed/index.jsx'),
    BtnAccount = require('./../button-register/button-account/button-account.jsx');

const style = require('./menu-toolbar.styles');

class MenuToolBar extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            logedIn: true,
            startMenuValue: 'parentid',
            showStartMenu: false,
            isOpenRekvPage: false,
            rekvId: props.rekvId ? props.rekvId : 0
        };


        this.btnStartClick = this.btnStartClick.bind(this);
        this.btnLoginClick = this.btnLoginClick.bind(this);
        this.renderStartMenu = this.renderStartMenu.bind(this);
        this.startMenuClickHandler = this.startMenuClickHandler.bind(this);
        this.handleChange = this.handleChange.bind(this);
        this.btnAccountClick = this.btnAccountClick.bind(this);
        this.btnEditRekvClick = this.btnEditRekvClick.bind(this);
        this.btnLinkClick = this.btnLinkClick.bind(this);

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
                },
                btnInfo: {
                    show: true,
                    disabled: false
                }
            };

        let userAccessList = [];


        if (('userAccessList' in DocContext.userData && DocContext.userData.userAccessList && DocContext.userData.userAccessList.length)) {
            userAccessList = DocContext.userData.userAccessList.map((row) => {
                let rowObject = JSON.parse(row);
                return {id: rowObject.id, kood: '', name: rowObject.nimetus};
            });

            // сортировка
            userAccessList = userAccessList.sort((a, b) => {
                return a.name.localeCompare(b.name, 'en', {sensitivity: 'base'})
            });

        }

        let asutus = '';
        let rekvId = this.state.rekvId;
        let asutus_obj = userAccessList.find(row => {
            return row.id == rekvId
        });

        if (asutus_obj && asutus_obj.name) {
            asutus = asutus_obj.name;
        }

        if (!DocContext.getUuid) {
            // потерял Uuid, на выход
            this.btnLoginClick()
        }

        return (
            <div style={style['container']}>
                <p style={style['pageName']}> {DocContext.pageName ? DocContext.pageName : 'Laste register'} </p>
                <ToolbarContainer
                    ref='menuToolbarContainer'
                    position="left">
                    <BtnStart ref='btnStart'
                              onClick={this.btnStartClick}
                              show={toolbarParams['btnStart'].show}
                              disabled={toolbarParams['btnStart'].disabled}
                    />
                    <BtnLink ref='btnLink'
                             value={'Lapsed'}
                             docTypeId='LAPS'
                             image={'laps'}
                             onClick={this.btnLinkClick}
                    />

                    <SelectRekv name='rekvId'
                                libs="rekv"
                                style={style['selectStyle']}
                                data={userAccessList}
                                readOnly={false}
                                value={rekvId}
                                defaultValue={asutus}
                                collId='id'
                                ref='rekvId'
                                onChange={this.handleChange}/>

                    <BtnEdit
                        ref='btnEditRekv'
                        value='Muuda'
                        onClick={this.btnEditRekvClick}
                    />
                    <BtnAccount ref='btnAccount'
                                value={DocContext.getUserName}
                                onClick={this.btnAccountClick}
                                show={toolbarParams['btnAccount'].show}
                                disabled={toolbarParams['btnAccount'].disabled}/>
                    <BtnLogin ref='btnLogin'
                              value={this.state.logedIn ? 'Välju' : 'Sisse'}
                              onClick={this.btnLoginClick}
                              show={toolbarParams['btnLogin'].show}
                              disabled={toolbarParams['btnLogin'].disabled}/>
                    <NoticeButton value={'teatised'}/>
                    <BtnInfo ref='btnInfo'
                             value={'Juhend'}
                             show={toolbarParams['btnInfo'].show}/>
                </ToolbarContainer>
                {this.renderStartMenu()}

            </div>
        );
    }

    renderStartMenu() {
        let component = null;
        let data = [];

        if (this.state.showStartMenu) {
            component = <StartMenu ref='startMenu'
                                   value={this.state.startMenuValue}
                                   data={data}
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
                pathname: `/${DocContext.getModule}/${value}`,
                state: {module: DocContext.getModule}

            });
        } else {
            document.location.href = `/${DocContext.getModule}/${value}`
        }
    }

    btnLoginClick() {
        const URL = '/logout';
        this.setState({logedIn: false});

        try {
            let userId = DocContext.getUserId;
            const params = {
                userId: userId, module: DocContext.getModule,
                uuid: this.state.logedIn ? DocContext.getUuid : null
            };

            fetchData.fetchDataPost(URL, params).then(() => {
                    DocContext.setUserData = null;
                }
            );
        } catch (e) {
            console.error(e);
        }
        window.location.href = '/login';
    }


    btnAccountClick() {
        return this.props.history.push({
            pathname: `/${DocContext.getModule}/userid/${DocContext.getUserId}`,
            state: {module: DocContext.getModule}
        });


    }

    btnLinkClick() {
        return this.props.history.push({
            pathname: `/${DocContext.getModule}/laps`,
            state: {module: DocContext.getModule}
        });

    }


    btnEditRekvClick() {
        return this.props.history.push({
            pathname: `/${DocContext.getModule}/rekv/${DocContext.getAsutusId}`,
            state: {module: DocContext.getModule}
        });

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
            let userId = this.state.logedIn ? DocContext.getUserId : null;
            let uuid = this.state.logedIn ? DocContext.getUuid : null;

            const params = {
                userId: userId,
                module: DocContext.getModule,
                docTypeId: DocContext.getDocTypeId,
                uuid: uuid
            };

            this.setState({rekvId: rekvId});

            fetchData.fetchDataPost(localUrl, params).then(response => {
                DocContext.setUserData = Object.assign(DocContext.userData, response.config.data);
                // проверим данные
                if (!response.data || !response.data.asutusId || rekvId !== response.data.asutusId) {
                    // что-то пошло не так
                    this.btnLoginClick();
                }

                // redirect to main
                this.props.history.push({
                    pathname: `/lapsed/`,
                });
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