package controllers

import (
	"context"
	"net/http"

	"github.com/alexliesenfeld/health"
	v1 "github.com/crowdsecurity/crowdsec/pkg/apiserver/controllers/v1"
	"github.com/crowdsecurity/crowdsec/pkg/csconfig"
	"github.com/crowdsecurity/crowdsec/pkg/csplugin"
	"github.com/crowdsecurity/crowdsec/pkg/database"
	"github.com/crowdsecurity/crowdsec/pkg/models"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type Controller struct {
	Ectx          context.Context
	DBClient      *database.Client
	Router        *gin.Engine
	Profiles      []*csconfig.ProfileCfg
	CAPIChan      chan []*models.Alert
	PluginChannel chan csplugin.ProfileAlert
	Log           *log.Logger
	ConsoleConfig *csconfig.ConsoleConfig
}

func (c *Controller) Init() error {
	if err := c.NewV1(); err != nil {
		return err
	}

	/* if we have a V2, just add

	if err := c.NewV2(); err != nil {
		return err
	}

	*/

	return nil
}

// endpoint for health checking
func serveHealth() http.HandlerFunc {
	checker := health.NewChecker(
		// just simple up/down status is enough
		health.WithDisabledDetails(),
		// no caching required
		health.WithDisabledCache(),
	)
	return health.NewHandler(checker)
}

func (c *Controller) NewV1() error {
	handlerV1, err := v1.New(c.DBClient, c.Ectx, c.Profiles, c.CAPIChan, c.PluginChannel, *c.ConsoleConfig)
	if err != nil {
		return err
	}

	c.Router.GET("/health", gin.WrapF(serveHealth()))
	c.Router.Use(v1.PrometheusMiddleware())
	c.Router.HandleMethodNotAllowed = true
	c.Router.NoRoute(func(ctx *gin.Context) {
		ctx.AbortWithStatus(http.StatusNotFound)
	})
	c.Router.NoMethod(func(ctx *gin.Context) {
		ctx.AbortWithStatus(http.StatusMethodNotAllowed)
	})

	groupV1 := c.Router.Group("/v1")
	groupV1.POST("/watchers", handlerV1.CreateMachine)
	groupV1.POST("/watchers/login", handlerV1.Middlewares.JWT.Middleware.LoginHandler)

	jwtAuth := groupV1.Group("")
	jwtAuth.GET("/refresh_token", handlerV1.Middlewares.JWT.Middleware.RefreshHandler)
	jwtAuth.Use(handlerV1.Middlewares.JWT.Middleware.MiddlewareFunc(), v1.PrometheusMachinesMiddleware())
	{
		jwtAuth.POST("/alerts", handlerV1.CreateAlert)
		jwtAuth.GET("/alerts", handlerV1.FindAlerts)
		jwtAuth.HEAD("/alerts", handlerV1.FindAlerts)
		jwtAuth.GET("/alerts/:alert_id", handlerV1.FindAlertByID)
		jwtAuth.HEAD("/alerts/:alert_id", handlerV1.FindAlertByID)
		jwtAuth.DELETE("/alerts", handlerV1.DeleteAlerts)
		jwtAuth.DELETE("/decisions", handlerV1.DeleteDecisions)
		jwtAuth.DELETE("/decisions/:decision_id", handlerV1.DeleteDecisionById)
	}

	apiKeyAuth := groupV1.Group("")
	apiKeyAuth.Use(handlerV1.Middlewares.APIKey.MiddlewareFunc(), v1.PrometheusBouncersMiddleware())
	{
		apiKeyAuth.GET("/decisions", handlerV1.GetDecision)
		apiKeyAuth.HEAD("/decisions", handlerV1.GetDecision)
		apiKeyAuth.GET("/decisions/stream", handlerV1.StreamDecision)
		apiKeyAuth.HEAD("/decisions/stream", handlerV1.StreamDecision)
	}

	return nil
}

/*
func (c *Controller) NewV2() error {
	handlerV2, err := v2.New(c.DBClient, c.Ectx)
	if err != nil {
		return err
	}

	v2 := c.Router.Group("/v2")
	v2.POST("/watchers", handlerV2.CreateMachine)
	v2.POST("/watchers/login", handlerV2.Middlewares.JWT.Middleware.LoginHandler)

	jwtAuth := v2.Group("")
	jwtAuth.GET("/refresh_token", handlerV2.Middlewares.JWT.Middleware.RefreshHandler)
	jwtAuth.Use(handlerV2.Middlewares.JWT.Middleware.MiddlewareFunc())
	{
		jwtAuth.POST("/alerts", handlerV2.CreateAlert)
		jwtAuth.GET("/alerts", handlerV2.FindAlerts)
		jwtAuth.DELETE("/alerts", handlerV2.DeleteAlerts)
		jwtAuth.DELETE("/decisions", handlerV2.DeleteDecisions)
		jwtAuth.DELETE("/decisions/:decision_id", handlerV2.DeleteDecisionById)
	}

	apiKeyAuth := v2.Group("")
	apiKeyAuth.Use(handlerV2.Middlewares.APIKey.MiddlewareFuncV2())
	{
		apiKeyAuth.GET("/decisions", handlerV2.GetDecision)
		apiKeyAuth.GET("/decisions/stream", handlerV2.StreamDecision)
	}

	return nil
}

*/
