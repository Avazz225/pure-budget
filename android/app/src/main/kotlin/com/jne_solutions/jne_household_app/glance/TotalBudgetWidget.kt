package com.jne_solutions.jne_household_app.glance

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.actionStartActivity

import com.jne_solutions.jne_household_app.MainActivity
import com.jne_solutions.jne_household_app.R

class TotalBudgetWidget : GlanceAppWidget() {

  /** Needed for Updating */
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { GlanceContent(context, currentState()) }
  }

  @Composable
  private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
    val data = currentState.preferences

    val totalBudget = data.getString("totalBudget", "")!!
    val currency = data.getString("currency", "")!!
    val language = data.getString("language", "")!!
    val totalConnector = data.getString("totalConnector", "")!!
    val totalFrom = data.getString("totalFrom", "")!!
    val fractionTotalBudget = data.getString("fractionTotalBudget", "")!!
    val opacity = data.getInt("backgroundOpacity", 255)
    val baseColorInt = context.getColor(R.color.widget_bg) // Int aus Ressourcen
    val baseColor = Color(baseColorInt)
    val backgroundColor = baseColor.copy(alpha = opacity / 255f)

    val langCode = language.take(2)

    val formattedAmount = if (langCode in listOf("de", "fr", "es", "it", "pt")) {
      "$totalBudget $currency"
    } else {
      "$currency $totalBudget"
    }

    val formattedFractionAmount = if (langCode in listOf("de", "fr", "es", "it", "pt")) {
      "$fractionTotalBudget $currency"
    } else {
      "$currency $fractionTotalBudget"
    }

    Box(
      modifier = GlanceModifier
      .background(ColorProvider(backgroundColor))
      .padding(16.dp)
      .clickable(
        onClick = actionStartActivity<MainActivity>(context))) {
          Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.Vertical.Top,
            horizontalAlignment = Alignment.CenterHorizontally,
          ) {
            Text(
              formattedFractionAmount,
              style = TextStyle(fontSize = 36.sp, fontWeight = FontWeight.Bold, color = ColorProvider(R.color.widget_text))
            )
            Text(
              "$totalFrom $formattedAmount $totalConnector",
              style = TextStyle(fontSize = 18.sp, color = ColorProvider(R.color.widget_text))
            )
          }
      }
  }
}