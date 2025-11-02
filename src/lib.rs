#![warn(clippy::all, rust_2018_idioms)]

use egui::{Color32, RichText, Slider, Ui};
use egui_flex::{Flex, FlexItem};
use egui_plot::{Legend, Line, Plot, PlotPoints};

type PlotData = (
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    Vec<[f64; 2]>,
    String,
    String,
);

pub struct TopApp {
    projectile_weight: f64,
    muzzle_velocity: f64,
    rifle_weight: f64,
    projectile_enabled: bool,
    velocity_enabled: bool,
    weight_enabled: bool,
    selection_order: Vec<&'static str>,
}

impl TopApp {
    pub fn new(_cc: &eframe::CreationContext<'_>) -> Self {
        Self {
            projectile_weight: 168.0,
            muzzle_velocity: 2650.0,
            rifle_weight: 12.0,
            projectile_enabled: true,
            velocity_enabled: true,
            weight_enabled: false,
            selection_order: vec!["projectile", "velocity"],
        }
    }

    fn calculate_kinetic_energy(grain_weight: f64, velocity_fps: f64) -> f64 {
        (grain_weight * velocity_fps.powi(2)) / 450_436.0
    }

    fn calculate_moa(kinetic_energy: f64, rifle_weight: f64) -> f64 {
        kinetic_energy / 200.0 / rifle_weight
    }

    fn calculate_value_for_1moa(&self) -> (f64, &'static str) {
        if self.projectile_enabled && self.velocity_enabled {
            let ke = Self::calculate_kinetic_energy(self.projectile_weight, self.muzzle_velocity);
            (ke / 200.0, "lbs")
        } else if self.projectile_enabled && self.weight_enabled {
            let target_ke = 200.0 * self.rifle_weight;
            (
                (target_ke * 450_436.0 / self.projectile_weight).sqrt(),
                "fps",
            )
        } else {
            // velocity_enabled && weight_enabled
            let target_ke = 200.0 * self.rifle_weight;
            (
                target_ke * 450_436.0 / (self.muzzle_velocity * self.muzzle_velocity),
                "gr",
            )
        }
    }

    fn render_config_bar(&mut self, ui: &mut Ui) {
        Flex::horizontal().show(ui, |flex| {
            // Checkbox section
            flex.add_ui(FlexItem::new(), |ui: &mut Ui| {
                ui.horizontal(|ui| {
                    ui.label("Select two variables:");

                    if ui
                        .checkbox(&mut self.projectile_enabled, "Projectile")
                        .clicked()
                    {
                        self.handle_selection("projectile");
                    }

                    if ui
                        .checkbox(&mut self.velocity_enabled, "Velocity")
                        .clicked()
                    {
                        self.handle_selection("velocity");
                    }

                    if ui
                        .checkbox(&mut self.weight_enabled, "Rifle Weight")
                        .clicked()
                    {
                        self.handle_selection("weight");
                    }
                });
            });

            flex.add_ui(FlexItem::new().basis(10.0).grow(0.0), |ui: &mut Ui| {
                ui.separator();
            });

            // Parameters section
            flex.add_ui(FlexItem::new(), |ui: &mut Ui| {
                ui.horizontal(|ui| {
                    ui.label("Parameters:");
                    self.render_parameters_inline(ui);
                });
            });
        });
    }

    fn handle_selection(&mut self, var: &'static str) {
        let is_enabled = match var {
            "projectile" => self.projectile_enabled,
            "velocity" => self.velocity_enabled,
            "weight" => self.weight_enabled,
            _ => return,
        };

        if is_enabled {
            // Variable was just enabled
            self.selection_order.push(var);

            // If we now have 3 selections, remove the oldest
            if self.selection_order.len() > 2 {
                let oldest = self.selection_order.remove(0);
                match oldest {
                    "projectile" => self.projectile_enabled = false,
                    "velocity" => self.velocity_enabled = false,
                    "weight" => self.weight_enabled = false,
                    _ => {}
                }
            }
        } else {
            // Variable was just disabled
            self.selection_order.retain(|&x| x != var);
        }
    }

    fn render_parameters_inline(&mut self, ui: &mut Ui) {
        if self.projectile_enabled {
            ui.label("Projectile:");
            ui.add(
                Slider::new(&mut self.projectile_weight, 50.0..=500.0)
                    .suffix(" gr")
                    .max_decimals(0),
            );
        }

        if self.velocity_enabled {
            ui.label("Velocity:");
            ui.add(
                Slider::new(&mut self.muzzle_velocity, 500.0..=5000.0)
                    .suffix(" fps")
                    .max_decimals(0),
            );
        }

        if self.weight_enabled {
            ui.label("Rifle:");
            ui.add(
                Slider::new(&mut self.rifle_weight, 5.0..=50.0)
                    .suffix(" lbs")
                    .max_decimals(1),
            );
        }

        let (value, unit) = self.calculate_value_for_1moa();
        if self.selection_order.len() == 2 {
            ui.label(format!("1 MOA @ {:.1} {}", value, unit));
        }
    }

    fn generate_plot_data(&self) -> PlotData {
        let num_points = 200;
        let mut expected_line = Vec::new();
        let mut sd1_upper = Vec::new();
        let mut sd1_lower = Vec::new();
        let mut sd2_upper = Vec::new();
        let mut sd2_lower = Vec::new();

        let (x_label, y_label) = if self.projectile_enabled && self.velocity_enabled {
            // Graph rifle weight
            for i in 0..num_points {
                let rifle_weight = 5.0 + (45.0 * i as f64) / (num_points - 1) as f64;
                let ke =
                    Self::calculate_kinetic_energy(self.projectile_weight, self.muzzle_velocity);
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
        } else if self.projectile_enabled && self.weight_enabled {
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
        } else {
            // Graph projectile weight (velocity && weight enabled)
            for i in 0..num_points {
                let projectile_weight = 50.0 + (450.0 * i as f64) / (num_points - 1) as f64;
                let ke = Self::calculate_kinetic_energy(projectile_weight, self.muzzle_velocity);
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

    fn render_plot(&self, ui: &mut Ui) {
        let (expected_line, sd1_upper, sd1_lower, sd2_upper, sd2_lower, x_label, y_label) =
            self.generate_plot_data();

        Plot::new("precision_plot")
            .legend(Legend::default())
            .x_axis_label(x_label)
            .y_axis_label(y_label)
            .allow_zoom(true)
            .allow_drag(true)
            .allow_scroll(true)
            .show(ui, |plot_ui| {
                // 2σ (95% confidence) - upper and lower bounds
                plot_ui.line(
                    Line::new("2σ (95%)", PlotPoints::new(sd2_upper))
                        .color(Color32::from_rgba_unmultiplied(255, 100, 100, 80))
                        .width(1.5),
                );
                plot_ui.line(
                    Line::new("", PlotPoints::new(sd2_lower))
                        .color(Color32::from_rgba_unmultiplied(255, 100, 100, 80))
                        .width(1.5),
                );

                // 1σ (68% confidence) - upper and lower bounds
                plot_ui.line(
                    Line::new("1σ (68%)", PlotPoints::new(sd1_upper))
                        .color(Color32::from_rgba_unmultiplied(255, 200, 0, 100))
                        .width(1.5),
                );
                plot_ui.line(
                    Line::new("", PlotPoints::new(sd1_lower))
                        .color(Color32::from_rgba_unmultiplied(255, 200, 0, 100))
                        .width(1.5),
                );

                // Expected line - draw last (on top)
                plot_ui.line(
                    Line::new("Expected Precision", PlotPoints::new(expected_line))
                        .color(Color32::from_rgb(30, 144, 255))
                        .width(2.5),
                );
            });
    }

    fn render_footer(&self, ui: &mut Ui) {
        ui.vertical(|ui| {
            ui.spacing_mut().item_spacing.y = 2.0;
            ui.label(
                RichText::new("Welcome to the r/longrange TOP Gun calculator.")
                    .small()
            );
            ui.label(
                RichText::new("This calculator is based on the TOP (Theory of Precision) Gun formula published by Applied Ballistics in Modern Advancements in Long Range Shooting, Vol 3.")
                    .small()
            );
            ui.label(
                RichText::new("This tool is provided for free by the moderator team of r/Longrange to help answer shooter questions and manage expectations for the precision (group size) of a given rifle.")
                    .small()
            );
            ui.label(
                RichText::new("Results from this tool are an estimate only, and rely on the use of a rifle and optic in good condition with no mechanical issues (scope problems, loose screws, etc) and commercial match grade ammo or comparable hand loads.")
                    .small()
            );
            ui.add_space(5.0);
            ui.horizontal(|ui| {
                ui.label(RichText::new("Community:").small().strong());
                ui.hyperlink_to("reddit/r/longrange", "https://reddit.com/r/longrange");
                ui.label(RichText::new("|").small());
                ui.label(RichText::new("Original:").small().strong());
                ui.hyperlink_to(
                    "TOP Gun Calculator Spreadsheet",
                    "https://docs.google.com/spreadsheets/d/1S0DMLcmj-Jvag5NwKrVAQUR2eOwpWTozy28jTVe998g/",
                );
            });
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
}
