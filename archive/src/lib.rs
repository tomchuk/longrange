#![warn(clippy::all, rust_2018_idioms)]

use egui::{Color32, ComboBox, RichText, Slider, Ui};
use egui_flex::{Flex, FlexItem};
use egui_plot::{Legend, Line, LineStyle, Plot, PlotPoints, Points};

type PlotData = (
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    String,
    String,
);

#[derive(Debug, Clone, Copy, PartialEq)]
enum GraphVariable {
    RifleWeight,
    Velocity,
    ProjectileWeight,
}

impl GraphVariable {
    fn label(&self) -> &'static str {
        match self {
            GraphVariable::RifleWeight => "Rifle Weight",
            GraphVariable::Velocity => "Velocity",
            GraphVariable::ProjectileWeight => "Projectile Weight",
        }
    }
}

pub struct TopApp {
    projectile_weight: f64,
    muzzle_velocity: f64,
    rifle_weight: f64,
    graph_variable: GraphVariable,
    hover_point: Option<[f64; 2]>,
}

impl TopApp {
    pub fn new(_cc: &eframe::CreationContext<'_>) -> Self {
        Self {
            projectile_weight: 168.0,
            muzzle_velocity: 2650.0,
            rifle_weight: 12.0,
            graph_variable: GraphVariable::RifleWeight,
            hover_point: None,
        }
    }

    fn calculate_kinetic_energy(grain_weight: f64, velocity_fps: f64) -> f64 {
        (grain_weight * velocity_fps.powi(2)) / 450_436.0
    }

    fn calculate_moa(kinetic_energy: f64, rifle_weight: f64) -> f64 {
        kinetic_energy / 200.0 / rifle_weight
    }

    fn calculate_value_for_1moa(&self) -> (f64, &'static str) {
        let ke = Self::calculate_kinetic_energy(self.projectile_weight, self.muzzle_velocity);
        match self.graph_variable {
            GraphVariable::RifleWeight => (ke / 200.0, "lbs"),
            GraphVariable::Velocity => {
                let target_ke = 200.0 * self.rifle_weight;
                (
                    (target_ke * 450_436.0 / self.projectile_weight).sqrt(),
                    "fps",
                )
            }
            GraphVariable::ProjectileWeight => {
                let target_ke = 200.0 * self.rifle_weight;
                (
                    target_ke * 450_436.0 / (self.muzzle_velocity * self.muzzle_velocity),
                    "gr",
                )
            }
        }
    }

    fn render_config_bar(&mut self, ui: &mut Ui) {
        let available_width = ui.available_width();
        let is_narrow = available_width < 800.0;

        if is_narrow {
            // Stack vertically on narrow screens
            ui.vertical(|ui| {
                // Graph selection
                ui.horizontal(|ui| {
                    ui.label("Graph:");
                    ComboBox::from_id_salt("graph_variable")
                        .selected_text(self.graph_variable.label())
                        .show_ui(ui, |ui| {
                            ui.selectable_value(
                                &mut self.graph_variable,
                                GraphVariable::RifleWeight,
                                "Rifle Weight",
                            );
                            ui.selectable_value(
                                &mut self.graph_variable,
                                GraphVariable::Velocity,
                                "Velocity",
                            );
                            ui.selectable_value(
                                &mut self.graph_variable,
                                GraphVariable::ProjectileWeight,
                                "Projectile Weight",
                            );
                        });
                });

                ui.add_space(5.0);
                ui.separator();
                ui.add_space(5.0);

                // Parameters section - stack vertically on mobile
                ui.vertical(|ui| {
                    self.render_parameters_stacked(ui);
                });
            });
        } else {
            // Horizontal layout for wider screens
            Flex::horizontal().show(ui, |flex| {
                // Graph selection
                flex.add_ui(FlexItem::new(), |ui: &mut Ui| {
                    ui.horizontal(|ui| {
                        ui.label("Graph:");
                        ComboBox::from_id_salt("graph_variable")
                            .selected_text(self.graph_variable.label())
                            .show_ui(ui, |ui| {
                                ui.selectable_value(
                                    &mut self.graph_variable,
                                    GraphVariable::RifleWeight,
                                    "Rifle Weight",
                                );
                                ui.selectable_value(
                                    &mut self.graph_variable,
                                    GraphVariable::Velocity,
                                    "Velocity",
                                );
                                ui.selectable_value(
                                    &mut self.graph_variable,
                                    GraphVariable::ProjectileWeight,
                                    "Projectile Weight",
                                );
                            });
                    });
                });

                flex.add_ui(FlexItem::new().basis(10.0).grow(0.0), |ui: &mut Ui| {
                    ui.separator();
                });

                // Parameters section
                flex.add_ui(FlexItem::new(), |ui: &mut Ui| {
                    ui.horizontal(|ui| {
                        self.render_parameters_inline(ui);
                    });
                });
            });
        }
    }

    fn render_parameters_inline(&mut self, ui: &mut Ui) {
        match self.graph_variable {
            GraphVariable::RifleWeight => {
                // Show projectile and velocity
                ui.label("Projectile:");
                ui.add(
                    Slider::new(&mut self.projectile_weight, 50.0..=500.0)
                        .suffix(" gr")
                        .max_decimals(0),
                );
                ui.label("Velocity:");
                ui.add(
                    Slider::new(&mut self.muzzle_velocity, 500.0..=5000.0)
                        .suffix(" fps")
                        .max_decimals(0),
                );
            }
            GraphVariable::Velocity => {
                // Show projectile and rifle weight
                ui.label("Projectile:");
                ui.add(
                    Slider::new(&mut self.projectile_weight, 50.0..=500.0)
                        .suffix(" gr")
                        .max_decimals(0),
                );
                ui.label("Rifle:");
                ui.add(
                    Slider::new(&mut self.rifle_weight, 5.0..=50.0)
                        .suffix(" lbs")
                        .max_decimals(1),
                );
            }
            GraphVariable::ProjectileWeight => {
                // Show velocity and rifle weight
                ui.label("Velocity:");
                ui.add(
                    Slider::new(&mut self.muzzle_velocity, 500.0..=5000.0)
                        .suffix(" fps")
                        .max_decimals(0),
                );
                ui.label("Rifle:");
                ui.add(
                    Slider::new(&mut self.rifle_weight, 5.0..=50.0)
                        .suffix(" lbs")
                        .max_decimals(1),
                );
            }
        }

        let (value, unit) = self.calculate_value_for_1moa();
        ui.label(format!("1 MOA @ {:.1} {}", value, unit));
    }

    fn render_parameters_stacked(&mut self, ui: &mut Ui) {
        match self.graph_variable {
            GraphVariable::RifleWeight => {
                // Show projectile and velocity
                ui.horizontal(|ui| {
                    ui.label("Projectile:");
                    ui.add(
                        Slider::new(&mut self.projectile_weight, 50.0..=500.0)
                            .suffix(" gr")
                            .max_decimals(0),
                    );
                });
                ui.horizontal(|ui| {
                    ui.label("Velocity:");
                    ui.add(
                        Slider::new(&mut self.muzzle_velocity, 500.0..=5000.0)
                            .suffix(" fps")
                            .max_decimals(0),
                    );
                });
            }
            GraphVariable::Velocity => {
                // Show projectile and rifle weight
                ui.horizontal(|ui| {
                    ui.label("Projectile:");
                    ui.add(
                        Slider::new(&mut self.projectile_weight, 50.0..=500.0)
                            .suffix(" gr")
                            .max_decimals(0),
                    );
                });
                ui.horizontal(|ui| {
                    ui.label("Rifle:");
                    ui.add(
                        Slider::new(&mut self.rifle_weight, 5.0..=50.0)
                            .suffix(" lbs")
                            .max_decimals(1),
                    );
                });
            }
            GraphVariable::ProjectileWeight => {
                // Show velocity and rifle weight
                ui.horizontal(|ui| {
                    ui.label("Velocity:");
                    ui.add(
                        Slider::new(&mut self.muzzle_velocity, 500.0..=5000.0)
                            .suffix(" fps")
                            .max_decimals(0),
                    );
                });
                ui.horizontal(|ui| {
                    ui.label("Rifle:");
                    ui.add(
                        Slider::new(&mut self.rifle_weight, 5.0..=50.0)
                            .suffix(" lbs")
                            .max_decimals(1),
                    );
                });
            }
        }

        let (value, unit) = self.calculate_value_for_1moa();
        ui.horizontal(|ui| {
            ui.label(format!("1 MOA @ {:.1} {}", value, unit));
        });
    }

    fn generate_plot_data(&self) -> PlotData {
        let num_points = 200;
        let mut expected_line = Vec::new();
        let mut sd1_upper = Vec::new();
        let mut sd1_lower = Vec::new();
        let mut sd2_upper = Vec::new();
        let mut sd2_lower = Vec::new();

        let (x_label, y_label) = match self.graph_variable {
            GraphVariable::RifleWeight => {
                // Graph rifle weight
                for i in 0..num_points {
                    let rifle_weight = 5.0 + (45.0 * i as f64) / (num_points - 1) as f64;
                    let ke = Self::calculate_kinetic_energy(
                        self.projectile_weight,
                        self.muzzle_velocity,
                    );
                    let moa = Self::calculate_moa(ke, rifle_weight);

                    expected_line.push([rifle_weight, moa]);
                    sd1_upper.push([rifle_weight, moa * 1.15]);
                    sd1_lower.push([rifle_weight, moa * 0.85]);
                    sd2_upper.push([rifle_weight, moa * 1.30]);
                    sd2_lower.push([rifle_weight, moa * 0.70]);
                }
                (
                    "Rifle Weight (lbs)".to_string(),
                    "5-Round Group Size (MOA)".to_string(),
                )
            }
            GraphVariable::Velocity => {
                // Graph velocity
                for i in 0..num_points {
                    let velocity = 500.0 + (4500.0 * i as f64) / (num_points - 1) as f64;
                    let ke = Self::calculate_kinetic_energy(self.projectile_weight, velocity);
                    let moa = Self::calculate_moa(ke, self.rifle_weight);

                    expected_line.push([velocity, moa]);
                    sd1_upper.push([velocity, moa * 1.15]);
                    sd1_lower.push([velocity, moa * 0.85]);
                    sd2_upper.push([velocity, moa * 1.30]);
                    sd2_lower.push([velocity, moa * 0.70]);
                }
                (
                    "Muzzle Velocity (fps)".to_string(),
                    "5-Round Group Size (MOA)".to_string(),
                )
            }
            GraphVariable::ProjectileWeight => {
                // Graph projectile weight
                for i in 0..num_points {
                    let projectile_weight = 50.0 + (450.0 * i as f64) / (num_points - 1) as f64;
                    let ke =
                        Self::calculate_kinetic_energy(projectile_weight, self.muzzle_velocity);
                    let moa = Self::calculate_moa(ke, self.rifle_weight);

                    expected_line.push([projectile_weight, moa]);
                    sd1_upper.push([projectile_weight, moa * 1.15]);
                    sd1_lower.push([projectile_weight, moa * 0.85]);
                    sd2_upper.push([projectile_weight, moa * 1.30]);
                    sd2_lower.push([projectile_weight, moa * 0.70]);
                }
                (
                    "Projectile Weight (grains)".to_string(),
                    "5-Round Group Size (MOA)".to_string(),
                )
            }
        };

        (
            expected_line,
            sd1_upper,
            sd1_lower,
            sd2_upper,
            sd2_lower,
            x_label,
            y_label,
        )
    }

    fn render_plot(&mut self, ui: &mut Ui) {
        let (expected_line, sd1_upper, sd1_lower, sd2_upper, sd2_lower, x_label, y_label) =
            self.generate_plot_data();

        // Determine units for tooltip
        let (x_unit, y_unit) = match self.graph_variable {
            GraphVariable::RifleWeight => ("lbs", "MOA"),
            GraphVariable::Velocity => ("fps", "MOA"),
            GraphVariable::ProjectileWeight => ("gr", "MOA"),
        };

        let hover_point = self.hover_point;
        Plot::new("precision_plot")
            .legend(Legend::default())
            .x_axis_label(x_label)
            .y_axis_label(y_label)
            .label_formatter(move |_name, _value| {
                if let Some(point) = hover_point {
                    format!("{:.1} {}\n{:.3} {}", point[0], x_unit, point[1], y_unit)
                } else {
                    String::new()
                }
            })
            .allow_zoom(true)
            .allow_drag(true)
            .allow_scroll(true)
            .show(ui, |plot_ui| {
                // 2σ (95% confidence) - upper and lower bounds
                plot_ui.line(
                    Line::new("2σ (95%)", PlotPoints::new(sd2_upper))
                        .color(Color32::from_rgba_unmultiplied(255, 100, 100, 80))
                        .width(1.5)
                        .style(LineStyle::Dotted { spacing: 10.0 }),
                );
                plot_ui.line(
                    Line::new("", PlotPoints::new(sd2_lower))
                        .color(Color32::from_rgba_unmultiplied(255, 100, 100, 80))
                        .width(1.5)
                        .style(LineStyle::Dotted { spacing: 10.0 }),
                );

                // 1σ (68% confidence) - upper and lower bounds
                plot_ui.line(
                    Line::new("1σ (68%)", PlotPoints::new(sd1_upper))
                        .color(Color32::from_rgba_unmultiplied(255, 200, 0, 100))
                        .width(1.5)
                        .style(LineStyle::Dotted { spacing: 10.0 }),
                );
                plot_ui.line(
                    Line::new("", PlotPoints::new(sd1_lower))
                        .color(Color32::from_rgba_unmultiplied(255, 200, 0, 100))
                        .width(1.5)
                        .style(LineStyle::Dotted { spacing: 10.0 }),
                );

                // Expected line - draw last (on top)
                plot_ui.line(
                    Line::new("Expected Precision", PlotPoints::new(expected_line.clone()))
                        .color(Color32::from_rgb(30, 144, 255))
                        .width(2.5),
                );

                // Draw marker on expected precision line at cursor position
                if let Some(hover_pos) = plot_ui.pointer_coordinate() {
                    // Find the closest point on the expected line to the cursor X position
                    if let Some(point_on_line) = expected_line.iter().min_by(|a, b| {
                        (a[0] - hover_pos.x)
                            .abs()
                            .partial_cmp(&(b[0] - hover_pos.x).abs())
                            .unwrap_or(std::cmp::Ordering::Equal)
                    }) {
                        // Store the point for the label formatter
                        self.hover_point = Some(*point_on_line);

                        // Draw a bold marker at this point
                        plot_ui.points(
                            Points::new("", vec![[point_on_line[0], point_on_line[1]]])
                                .color(Color32::from_rgb(30, 144, 255))
                                .radius(6.0)
                                .shape(egui_plot::MarkerShape::Circle)
                                .filled(true),
                        );
                    }
                } else {
                    self.hover_point = None;
                }
            });
    }

    fn render_footer(&self, ui: &mut Ui) {
        let available_width = ui.available_width();
        let is_narrow = available_width < 600.0;

        ui.vertical(|ui| {
            ui.spacing_mut().item_spacing.y = 2.0;
            ui.label("Welcome to the r/longrange TOP Gun calculator.");
            ui.label("This calculator is based on the TOP (Theory of Precision) Gun formula published by Applied Ballistics in Modern Advancements in Long Range Shooting, Vol 3.");
            ui.label("This tool is provided for free by the moderator team of r/Longrange to help answer shooter questions and manage expectations for the precision (group size) of a given rifle.");
            ui.label("Results from this tool are an estimate only, and rely on the use of a rifle and optic in good condition with no mechanical issues (scope problems, loose screws, etc) and commercial match grade ammo or comparable hand loads.");
            ui.add_space(5.0);

            if is_narrow {
                // Stack vertically on narrow screens
                ui.vertical(|ui| {
                    ui.horizontal(|ui| {
                        ui.label(RichText::new("Community:").strong());
                        ui.hyperlink_to("reddit/r/longrange", "https://reddit.com/r/longrange");
                    });
                    ui.horizontal(|ui| {
                        ui.label(RichText::new("Original:").strong());
                        ui.hyperlink_to(
                            "TOP Gun Calculator Spreadsheet",
                            "https://docs.google.com/spreadsheets/d/1S0DMLcmj-Jvag5NwKrVAQUR2eOwpWTozy28jTVe998g/",
                        );
                    });
                });
            } else {
                // Horizontal layout for wider screens
                ui.horizontal(|ui| {
                    ui.label(RichText::new("Community:").strong());
                    ui.hyperlink_to("reddit/r/longrange", "https://reddit.com/r/longrange");
                    ui.label("|");
                    ui.label(RichText::new("Original:").strong());
                    ui.hyperlink_to(
                        "TOP Gun Calculator Spreadsheet",
                        "https://docs.google.com/spreadsheets/d/1S0DMLcmj-Jvag5NwKrVAQUR2eOwpWTozy28jTVe998g/",
                    );
                });
            }
        });
    }
}

impl eframe::App for TopApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::TopBottomPanel::top("config_panel").show(ctx, |ui| {
            egui::Frame::default()
                .fill(ui.style().visuals.faint_bg_color)
                .inner_margin(egui::vec2(10.0, 10.0))
                .show(ui, |ui| {
                    self.render_config_bar(ui);
                });
        });

        egui::TopBottomPanel::bottom("footer_panel").show(ctx, |ui| {
            self.render_footer(ui);
        });

        egui::CentralPanel::default().show(ctx, |ui| {
            // Full-width plot in remaining space
            self.render_plot(ui);
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_kinetic_energy_calculation() {
        // Test with 168 grain bullet at 2650 fps
        let ke = TopApp::calculate_kinetic_energy(168.0, 2650.0);
        // Expected: (168 * 2650^2) / 450436 = 2619.96
        assert!((ke - 2619.96).abs() < 1.0);
    }

    #[test]
    fn test_kinetic_energy_known_values() {
        // 150 grain at 3000 fps
        let ke = TopApp::calculate_kinetic_energy(150.0, 3000.0);
        assert!((ke - 2997.10).abs() < 1.0);

        // 55 grain at 3240 fps (common .223)
        let ke = TopApp::calculate_kinetic_energy(55.0, 3240.0);
        assert!((ke - 1281.75).abs() < 1.0);
    }

    #[test]
    fn test_moa_calculation() {
        // 2620 ft-lbs with 12 lb rifle
        let moa = TopApp::calculate_moa(2620.0, 12.0);
        // Expected: 2620 / 200 / 12 = 1.092
        assert!((moa - 1.092).abs() < 0.01);
    }

    #[test]
    fn test_moa_heavier_rifle() {
        // Heavier rifle should have better precision (lower MOA)
        let ke = 2620.0;
        let moa_light = TopApp::calculate_moa(ke, 8.0);
        let moa_heavy = TopApp::calculate_moa(ke, 16.0);
        assert!(moa_heavy < moa_light);
    }

    #[test]
    fn test_full_calculation_chain() {
        // .308 Win: 168gr @ 2650fps, 12lb rifle
        let ke = TopApp::calculate_kinetic_energy(168.0, 2650.0);
        let moa = TopApp::calculate_moa(ke, 12.0);
        // Should be around 1.09 MOA
        assert!(moa > 1.0 && moa < 1.2);
    }

    #[test]
    fn test_edge_cases() {
        // Minimum values
        let ke_min = TopApp::calculate_kinetic_energy(50.0, 500.0);
        assert!(ke_min > 0.0);

        let moa_min = TopApp::calculate_moa(ke_min, 5.0);
        assert!(moa_min > 0.0);

        // Maximum values
        let ke_max = TopApp::calculate_kinetic_energy(500.0, 5000.0);
        assert!(ke_max > 0.0);

        let moa_max = TopApp::calculate_moa(ke_max, 50.0);
        assert!(moa_max > 0.0);
    }

    #[test]
    fn test_graph_variable_selection() {
        let mut app = TopApp {
            projectile_weight: 168.0,
            muzzle_velocity: 2650.0,
            rifle_weight: 12.0,
            graph_variable: GraphVariable::RifleWeight,
        };

        // Test RifleWeight selection
        assert_eq!(app.graph_variable, GraphVariable::RifleWeight);
        let (_value, unit) = app.calculate_value_for_1moa();
        assert_eq!(unit, "lbs");

        // Test Velocity selection
        app.graph_variable = GraphVariable::Velocity;
        let (_value, unit) = app.calculate_value_for_1moa();
        assert_eq!(unit, "fps");

        // Test ProjectileWeight selection
        app.graph_variable = GraphVariable::ProjectileWeight;
        let (_value, unit) = app.calculate_value_for_1moa();
        assert_eq!(unit, "gr");
    }

    #[test]
    fn test_graph_variable_labels() {
        assert_eq!(GraphVariable::RifleWeight.label(), "Rifle Weight");
        assert_eq!(GraphVariable::Velocity.label(), "Velocity");
        assert_eq!(GraphVariable::ProjectileWeight.label(), "Projectile Weight");
    }
}
